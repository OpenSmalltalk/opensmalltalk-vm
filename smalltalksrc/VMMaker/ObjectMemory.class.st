"
This class describes a 32-bit direct-pointer object memory for Smalltalk.  The model is very simple in principle:  a pointer is either a SmallInteger or a 32-bit direct object pointer.

SmallIntegers are tagged with a low-order bit equal to 1, and an immediate 31-bit 2s-complement signed value in the rest of the word.

All object pointers point to a header, which may be followed by a number of data fields.  This object memory achieves considerable compactness by using a variable header size (the one complexity of the design).  The format of the 0th header word is as follows:
	3 bits	reserved for gc (mark, old, dirty)
	12 bits	object hash (for HashSets)
	5 bits	compact class index
	4 bits	object format
	6 bits	object size in 32-bit words
	2 bits	header type (0: 3-word, 1: 2-word, 2: forbidden, 3: 1-word)

If a class is in the compact class table, then this is the only header information needed.  If it is not, then it will have another header word at offset -4 bytes with its class in the high 30 bits, and the header type repeated in its low 2 bits.  It the objects size is greater than 255 bytes, then it will have yet another header word at offset -8 bytes with its full word size in the high 30 bits and its header type repeated in the low two bits.

The object format field provides the remaining information as given in the formatOf: method (including isPointers, isVariable, isBytes, and the low 2 size bits of byte-sized objects).

This implementation includes incremental (2-generation) and full garbage collection, each with compaction and rectification of direct pointers.  It also supports a bulk-become (exchange object identity) feature that allows many objects to be becomed at once, as when all instances of a class must be grown or shrunk.
"
Class {
	#name : #ObjectMemory,
	#superclass : #Object,
	#instVars : [
		'memory',
		'youngStart',
		'endOfMemory',
		'memoryLimit',
		'nilObj',
		'falseObj',
		'trueObj',
		'specialObjectsOop',
		'rootTable',
		'rootTableCount',
		'child',
		'field',
		'parentField',
		'freeBlock',
		'lastHash',
		'allocationCount',
		'lowSpaceThreshold',
		'signalLowSpace',
		'compStart',
		'compEnd',
		'fwdTableNext',
		'fwdTableLast',
		'remapBuffer',
		'remapBufferCount',
		'allocationsBetweenGCs',
		'tenuringThreshold',
		'statFullGCs',
		'statFullGCMSecs',
		'statIncrGCs',
		'statIncrGCMSecs',
		'statTenures',
		'statRootTableOverflows',
		'freeContexts',
		'freeLargeContexts',
		'interruptCheckCounter',
		'totalObjectCount',
		'shrinkThreshold',
		'growHeadroom',
		'headerTypeBytes',
		'youngStartLocal'
	],
	#classVars : [
		'ClassBitmap',
		'ClassFloat',
		'ClassMethodContext',
		'HashBitsOffset',
		'RootTableRedZone',
		'FalseObject',
		'BaseHeaderSize',
		'RootTableSize',
		'HeaderTypeGC',
		'FloatProto',
		'CtxtTempFrameStart',
		'BlockContextProto',
		'StartObj',
		'NilObject',
		'SchedulerAssociation',
		'MethodContextProto',
		'TheDisplay',
		'SelectorAboutToReturn',
		'HashBits',
		'DoBalanceChecks',
		'ClassTranslatedMethod',
		'ConstTwo',
		'TheLowSpaceSemaphore',
		'ClassMessage',
		'TypeMask',
		'DoAssertionChecks',
		'ClassCharacter',
		'ClassExternalLibrary',
		'SelectorMustBeBoolean',
		'CompactClassMask',
		'ConstOne',
		'SelectorDoesNotUnderstand',
		'TheFinalizationSemaphore',
		'ConstMinusOne',
		'ConstZero',
		'ExternalObjectsArray',
		'StackStart',
		'AllButMarkBit',
		'ClassProcess',
		'SizeMask',
		'ClassLargePositiveInteger',
		'GCTopMarker',
		'MarkBit',
		'ClassExternalAddress',
		'SelectorCannotInterpret',
		'ClassPseudoContext',
		'ClassLargeNegativeInteger',
		'HeaderTypeFree',
		'LargeContextBit',
		'ClassInteger',
		'AllButRootBit',
		'AllButMarkBitAndTypeMask',
		'ClassBlockContext',
		'TrueObject',
		'SpecialSelectors',
		'RemapBufferSize',
		'RootBit',
		'ClassSemaphore',
		'CharacterTable',
		'ClassPoint',
		'TheTimerSemaphore',
		'ClassString',
		'Done',
		'Upward',
		'TheInterruptSemaphore',
		'SmallContextSize',
		'AllButTypeMask',
		'AllButHashBits',
		'ClassExternalStructure',
		'CompactClasses',
		'StartField',
		'ClassArray',
		'SelectorCannotReturn',
		'NilContext',
		'ClassExternalData',
		'HeaderTypeClass',
		'TheInputSemaphore',
		'ClassByteArray',
		'LargeContextSize',
		'HeaderTypeShort',
		'SelectorRunWithIn',
		'HeaderTypeSizeAndClass',
		'ClassCompiledMethod',
		'ClassExternalFunction'
	],
	#classInstVars : [
		'timeStamp'
	],
	#category : 'VMMaker-Interpreter'
}

{ #category : #translation }
ObjectMemory class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: #memory type: #'unsigned char*'.
	aCCodeGenerator
		var: #remapBuffer
		declareC: 'int remapBuffer[', (RemapBufferSize + 1) printString, ']'.
	aCCodeGenerator
		var: #rootTable
		declareC: 'int rootTable[', (RootTableSize + 1) printString, ']'.
	aCCodeGenerator
		var: #headerTypeBytes
		declareC: 'int headerTypeBytes[4]'.
		
]

{ #category : #initialization }
ObjectMemory class >> initialize [
	"ObjectMemory initialize"

	"Translation flags (booleans that control code generation via conditional translation):"
	DoAssertionChecks _ false.  "generate assertion checks"
	DoBalanceChecks _ false. "generate stack balance checks"

	self initializeSpecialObjectIndices.
	self initializeObjectHeaderConstants.

	SmallContextSize _ 92.  "16 indexable fields"
	LargeContextSize _ 252.  "56 indexable fileds.  Max with single header word."
	LargeContextBit _ 16r40000.  "This bit set in method headers if large context is needed."
	CtxtTempFrameStart _ 6.  "Copy of TempFrameStart in Interp"
	NilContext _ 1.  "the oop for the integer 0; used to mark the end of context lists"

	RemapBufferSize _ 25.
	RootTableSize _ 2500.  	"number of root table entries (4 bytes/entry)"
	RootTableRedZone _ RootTableSize - 100.	"red zone of root table - when reached we force IGC"

	"tracer actions"
	StartField _ 1.
	StartObj _ 2.
	Upward _ 3.
	Done _ 4.
]

{ #category : #initialization }
ObjectMemory class >> initializeObjectHeaderConstants [

	BaseHeaderSize _ 4.

	"masks for type field"
	TypeMask _ 3.
	AllButTypeMask _ 16rFFFFFFFF - TypeMask.

	"type field values"
	HeaderTypeSizeAndClass _ 0.
	HeaderTypeClass _ 1.
	HeaderTypeFree _ 2.
	HeaderTypeShort _ 3.

	"type field values used during the mark phase of GC"
	HeaderTypeGC _ 2.
	GCTopMarker _ 3.  "neither an oop, nor an oop+1, this value signals that we have crawled back up to the top of the marking phase."

	"base header word bit fields"
	HashBits _ 16r1FFE0000.
	AllButHashBits _ 16rFFFFFFFF - HashBits.
	HashBitsOffset _ 17.
	SizeMask _ 16rFC.
	CompactClassMask _ 16r1F000.

	"masks for root and mark bits"
	MarkBit _ 16r80000000.
	RootBit _ 16r40000000.
	AllButMarkBit _ 16rFFFFFFFF - MarkBit.
	AllButRootBit _ 16rFFFFFFFF - RootBit.

	AllButMarkBitAndTypeMask _ AllButTypeMask - MarkBit.
]

{ #category : #initialization }
ObjectMemory class >> initializeSpecialObjectIndices [
	"Initialize indices into specialObjects array."

	NilObject _ 0.
	FalseObject _ 1.
	TrueObject _ 2.
	SchedulerAssociation _ 3.
	ClassBitmap _ 4.
	ClassInteger _ 5.
	ClassString _ 6.
	ClassArray _ 7.
	"SmalltalkDictionary _ 8."  "Do not delete!"
	ClassFloat _ 9.
	ClassMethodContext _ 10.
	ClassBlockContext _ 11.
	ClassPoint _ 12.
	ClassLargePositiveInteger _ 13.
	TheDisplay _ 14.
	ClassMessage _ 15.
	ClassCompiledMethod _ 16.
	TheLowSpaceSemaphore _ 17.
	ClassSemaphore _ 18.
	ClassCharacter _ 19.
	SelectorDoesNotUnderstand _ 20.
	SelectorCannotReturn _ 21.
	TheInputSemaphore _ 22.
	SpecialSelectors _ 23.
	CharacterTable _ 24.
	SelectorMustBeBoolean _ 25.
	ClassByteArray _ 26.
	ClassProcess _ 27.
	CompactClasses _ 28.
	TheTimerSemaphore _ 29.
	TheInterruptSemaphore _ 30.
	FloatProto _ 31.
	SelectorCannotInterpret _ 34.
	MethodContextProto _ 35.
	BlockContextProto _ 37.
	ExternalObjectsArray _ 38.
	ClassPseudoContext _ 39.
	ClassTranslatedMethod _ 40.
	TheFinalizationSemaphore _ 41.
	ClassLargeNegativeInteger _ 42.

	ClassExternalAddress _ 43.
	ClassExternalStructure _ 44.
	ClassExternalData _ 45.
	ClassExternalFunction _ 46.
	ClassExternalLibrary _ 47.

	SelectorAboutToReturn _ 48.
	SelectorRunWithIn _ 49.

]

{ #category : #translation }
ObjectMemory class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	self touch.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #translation }
ObjectMemory class >> requiredMethodNames [
	"return the list of method names that should be retained for export or other support reasons"
	^ #(checkedLongAt: allocateChunk: firstAccessibleObject noteAsRoot:headerLoc: splObj:)
]

{ #category : #translation }
ObjectMemory class >> timeStamp [
	^timeStamp ifNil:[0]
]

{ #category : #accessing }
ObjectMemory class >> touch [
	timeStamp _ Time totalSeconds
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> aComment [
	"The mark phase is based on a pointer reversing traversal. This is a little tricky because the class, which is needed by the traversal, may be in either the header (as a compact class index) or in the word above the header. See memo 'Revised object format'.
	Compact classes are marked and traced separately.
	How do you know that you are returning from having marked a class? Parent pointer has 10 in low bits.

Here are the states an object may be in, followed by what to do next in brackets []:

  Start Object: parentField is set, [obj _ child]:
	obj is pointed at by a field in parent that is being traced now. obj is marked.
		[(parent goes up to the next field) field addr _ obj. go to Upward]
	obj is pointed at by a field in parent that is being traced now. obj is unmarked. obj has no pointers.
		[put 10 into low bits of header. field addr _ obj. go to Start Field (to process class word)]
	obj is pointed at by a field in parent that is being traced now. obj is unmarked. obj has pointers.
		[put 10 into low bits of header. point to last field. go to Start Field]

  Start Field: 
	Field ends in 10. It is the header. Short Class is not 0.
		[Set low bits to correct value. (have parent pointer) go to Upward]
	Field ends in 10. It is the header. Short Class is 0.
		[child _ word above header. low bits of child _ 01. class word _ parentField. parentField _ loc of class word. go to Start Obj]
	Field is Integer.
		[point one word up, go to Start Field]
	Field is oop.
		[child _ field. field _ parentField. parentField _ loc of field. go to Start Obj]

  Upward [restore low bits of header (at field addr)]:
	parentField is 3. (bits 11, int 1).
		[done!]
	parentField ends in 00.
		[child _ field addr. field addr _ parentField. parentField _ field addr contents.
		field addr contents _ child (addr of prev object. its oop). field addr - 4. go to Start Field]
	parentField ends in 01. Were tracing the class.
		[child _ field addr. field addr _ parentField (loc of class word). parentField _ field addr contents.
		field addr contents _ child (addr of prev object. its oop). field addr + 4 (header). go to Upward]
"
]

{ #category : #finalization }
ObjectMemory >> aFinalizationComment [
	"This finalization scheme assumes to have weak classes in which the fields are not traced during the mark phase of a GC. This means, if an object is referenced only by any instances of weak classes it can be collected. In turn, we need to find out if an object referenced by a weak class is actually being collected because we have to invalidate the weak object pointer and to signal that the object has gone.
	How do we know that an object referenced by a weak class is being collected? Well,  this is based on two observations. First, objects will not change their relative locations in memory, meaning that if object A is created BEFORE object B it will always have a physical memory address which is LESS than B. Secondly, GC always works from a given starting address (youngStart during incremental GC; startOfMemory during fullGC) up to end of memory. If we can somehow garantuee that the weak reference is created after the object it points to we can easily implement the following simple scheme:
	1) Mark phase
		Do not trace the fields of any instances of weak classes.
	2) Sweep phase:
		a) Explicitly mark all free objects.
		b) 	If a weak reference is encountered check the the object it points to. 
			If the object is marked as free than we know that this weak reference's object is gone.
			Signal that it is gone.

	There is, however, one small problem with this approach. We cannot always garantuee that WeakReferences point backwards such as in the following piece of code:
		| o1 o2 w1 w2 |
		o1 _ Object new.
		w1 _ WeakReference on: o1.
		o2 _ Object new.
		w2 _ WeakReference on: o2.
		o1 become: o2.
The become: operation makes w1 point to o2 and because o2 has been created AFTER w1 the object reference in w1 points forward. Why might this be a problem? Well, if the GC would start after the weak reference AND free the object then the weak reference would simply point to an invalid memory location (since we've not been checking the weak reference during sweep phase).

	Fortunately, this can not happen in the current ObjectMemory implementation. Why? Well, the only GC not starting at the beginning of the memory is incremental GC. Incremental GC however is only executed in so-called youngSpace. If both, the weak reference AND the object it points to reside in youngSpace then we can still check the weak reference. If however, the weak reference is not in youngSpace but the object is, then the object is itself a root in young space and will be marked by the GC even if it is only referenced by the WeakReference.

	In the end, we just need a little adjustment in step 2b) of the above procedure which looks as follows:
		If the weak reference points 
			* backwards: check if the object header is marked free
			* forwards: check if the object has been marked in markPhase.

	Note that a number of finalizations will only be executed during a fullGC. This happens if either the WeakReference or the object reside outside youngSpace. So, if you must garantuee that some object has been finalized you definitely need to do a fullGC.

ar 3/20/98 17:20"

	self error:'Comment only'.
]

{ #category : #'object enumeration' }
ObjectMemory >> accessibleObjectAfter: oop [ 
	"Return the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted."
	| obj |
	self inline: false.
	obj _ self objectAfter: oop.
	[obj < endOfMemory]
		whileTrue: [(self isFreeObject: obj) ifFalse: [^ obj].
			obj _ self objectAfter: obj].
	^ nil
]

{ #category : #initialization }
ObjectMemory >> adjustAllOopsBy: bytesToShift [ 
	"Adjust all oop references by the given number of bytes. This 
	is done just after reading in an image when the new base 
	address of the object heap is different from the base address 
	in the image."
	"di 11/18/2000 - return number of objects found"
	| oop totalObjects |
	self inline: false.
	bytesToShift = 0 ifTrue: [^ 300000].
	"this is probably an improvement over the previous answer of 
	nil, but maybe we should do the obejct counting loop and 
	simply guard the adjustFieldsAndClass... with a bytesToShift 
	= 0 ifFalse: ?"
	totalObjects _ 0.
	oop _ self firstObject.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [totalObjects _ totalObjects + 1.
					self adjustFieldsAndClassOf: oop by: bytesToShift].
			oop _ self objectAfter: oop].
	^ totalObjects
]

{ #category : #initialization }
ObjectMemory >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
	"Adjust all pointers in this object by the given offset."
	| fieldAddr fieldOop classHeader newClassOop |
	self inline: true.
	fieldAddr _ oop + (self lastPointerOf: oop).
	[fieldAddr > oop]
		whileTrue: [fieldOop _ self longAt: fieldAddr.
			(self isIntegerObject: fieldOop)
				ifFalse: [self longAt: fieldAddr put: fieldOop + offsetBytes].
			fieldAddr _ fieldAddr - 4].
	(self headerType: oop) ~= HeaderTypeShort
		ifTrue: ["adjust class header if not a compact class"
			classHeader _ self longAt: oop - 4.
			newClassOop _ (classHeader bitAnd: AllButTypeMask) + offsetBytes.
			self longAt: oop - 4 put: (newClassOop bitOr: (classHeader bitAnd: TypeMask))]
]

{ #category : #become }
ObjectMemory >> allYoung: array1 and: array2 [ 
	"Return true if all the oops in both arrays, and the arrays 
	themselves, are in the young object space."
	| fieldOffset |
	array1 < youngStart ifTrue: [^ false].
	array2 < youngStart ifTrue: [^ false].
	fieldOffset _ self lastPointerOf: array1.
	"same size as array2"
	[fieldOffset >= BaseHeaderSize]
		whileTrue: [(self longAt: array1 + fieldOffset) < youngStart ifTrue: [^ false].
			(self longAt: array2 + fieldOffset) < youngStart ifTrue: [^ false].
			fieldOffset _ fieldOffset - 4].
	^ true
]

{ #category : #allocation }
ObjectMemory >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill with: fillWord [ 
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes space for the base header word.) Initialize the header fields of the new object and fill the remainder of the object with the given value.
	May cause a GC"
	| newObj remappedClassOop end i |
	self inline: true.

	"remap classOop in case GC happens during allocation"
	hdrSize > 1 ifTrue: [self pushRemappableOop: classOop].
	newObj _ self allocateChunk: byteSize + (hdrSize - 1 * 4).
	hdrSize > 1 ifTrue: [remappedClassOop _ self popRemappableOop].

	hdrSize = 3
		ifTrue: [self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + 4 put: (remappedClassOop bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + 8 put: (baseHeader bitOr: HeaderTypeSizeAndClass).
			newObj _ newObj + 8].

	hdrSize = 2
		ifTrue: [self longAt: newObj put: (remappedClassOop bitOr: HeaderTypeClass).
			self longAt: newObj + 4 put: (baseHeader bitOr: HeaderTypeClass).
			newObj _ newObj + 4].

	hdrSize = 1
		ifTrue: [self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].
	"clear new object"
	doFill ifTrue: [end _ newObj + byteSize.
			i _ newObj + 4.
			[i < end] whileTrue: [self longAt: i put: fillWord.
					i _ i + 4]].
	DoAssertionChecks
		ifTrue: [self okayOop: newObj.
			self oopHasOkayClass: newObj.
			(self objectAfter: newObj) = freeBlock
				ifFalse: [self error: 'allocate bug: did not set header of new oop correctly'].
			(self objectAfter: freeBlock) = endOfMemory
				ifFalse: [self error: 'allocate bug: did not set header of freeBlock correctly']].

	^newObj
]

{ #category : #allocation }
ObjectMemory >> allocateChunk: byteSize [ 
	"Allocate a chunk of the given size. Sender must be sure that  the requested size includes enough space for the header  word(s). " 
	"Details: To limit the time per incremental GC, do one every so many allocations. The number is settable via primitiveVMParameter to tune your memory system"
	| enoughSpace newFreeSize newChunk |
	self inline: true.

	allocationCount >= allocationsBetweenGCs
		ifTrue: ["do an incremental GC every so many allocations to  keep pauses short"
			self incrementalGC].

	enoughSpace _ self sufficientSpaceToAllocate: byteSize.
	enoughSpace
		ifFalse: ["signal that space is running low, but proceed with allocation if possible"
			signalLowSpace _ true.
			lowSpaceThreshold _ 0. "disable additional interrupts until lowSpaceThreshold is reset by image"
			self forceInterruptCheck].
	(self cCoerce: (self sizeOfFree: freeBlock) to: 'unsigned ') < (self cCoerce: byteSize + BaseHeaderSize to: 'unsigned ')
		ifTrue: [self error: 'out of memory'].

	"if we get here, there is enough space for allocation to  succeed "
	newFreeSize _ (self sizeOfFree: freeBlock) - byteSize.
	newChunk _ freeBlock.
	freeBlock _ freeBlock + byteSize.

	"Assume: client will initialize object header of free chunk, so following is not needed:"
	"self setSizeOfFree: newChunk to: byteSize."
	self setSizeOfFree: freeBlock to: newFreeSize.
	allocationCount _ allocationCount + 1.

	^newChunk
]

{ #category : #allocation }
ObjectMemory >> allocateOrRecycleContext: needsLarge [
	"Return a recycled context or a newly allocated one if none is available for recycling."
	| cntxt |
	needsLarge = 0
	ifTrue: [freeContexts ~= NilContext ifTrue:
				[cntxt _ freeContexts.
				freeContexts _ self fetchPointer: 0 ofObject: cntxt.
				^ cntxt]]
	ifFalse: [freeLargeContexts ~= NilContext ifTrue:
				[cntxt _ freeLargeContexts.
				freeLargeContexts _ self fetchPointer: 0 ofObject: cntxt.
				^ cntxt]].
	
	needsLarge = 0
		ifTrue: [cntxt _ self instantiateContext: (self splObj: ClassMethodContext)
				sizeInBytes: SmallContextSize]
		ifFalse: [cntxt _ self instantiateContext: (self splObj: ClassMethodContext)
				sizeInBytes: LargeContextSize].
	"Required init -- above does not fill w/nil.  All others get written."
	self storePointerUnchecked: 4 "InitialIPIndex" ofObject: cntxt
					withValue: nilObj.
	^ cntxt

]

{ #category : #'header access' }
ObjectMemory >> baseHeader: oop [

	^ self longAt: oop
]

{ #category : #'garbage collection' }
ObjectMemory >> beRootIfOld: oop [ 
	"If this object is old, mark it as a root (because a new object 
	may be stored into it)"
	self inline: false.
	(oop < youngStart and: [(self isIntegerObject: oop) not])
		ifTrue: ["Yes, oop is an old object"
			self noteAsRoot: oop headerLoc: oop]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> beRootWhileForwarding: oop [
	"Record that the given oop in the old object area points to an object in the young area when oop may be forwarded."
	"Warning: No young objects should be recorded as roots. Callers are responsible for ensuring this constraint is not violated."

	| header fwdBlock |
	header _ self longAt: oop.
	(header bitAnd: MarkBit) ~= 0
		ifTrue: ["This oop is forwarded"
				fwdBlock _ (header bitAnd: AllButMarkBitAndTypeMask) << 1.
				DoAssertionChecks ifTrue: [ self fwdBlockValidate: fwdBlock ].
				self noteAsRoot: oop headerLoc: fwdBlock + 4]
		ifFalse: ["Normal -- no forwarding"
				self noteAsRoot: oop headerLoc: oop]
]

{ #category : #become }
ObjectMemory >> become: array1 with: array2 [

	^ self become: array1 with: array2 twoWay: true copyHash: true

]

{ #category : #become }
ObjectMemory >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag [ 
	"All references to each object in array1 are swapped with all references to the corresponding object in array2. That is, all pointers to one object are replaced with with pointers to the other. The arguments must be arrays of the same length. 
	Returns true if the primitive succeeds."
	"Implementation: Uses forwarding blocks to update references as done in compaction."
	(self isArray: array1) ifFalse: [^false].
	(self isArray: array2) ifFalse: [^false].
	(self lastPointerOf: array1) = (self lastPointerOf: array2) ifFalse: [^false].
	(self containOnlyOops: array1 and: array2) ifFalse: [^false].

	(self prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag) ifFalse: [^false]. "fail; not enough space for forwarding table"

	(self allYoung: array1 and: array2)
		ifTrue: ["sweep only the young objects plus the roots"
			self mapPointersInObjectsFrom: youngStart to: endOfMemory]
		ifFalse: ["sweep all objects"
			self mapPointersInObjectsFrom: self startOfMemory to: endOfMemory].
	twoWayFlag
		ifTrue: [self restoreHeadersAfterBecoming: array1 with: array2]
		ifFalse: [self restoreHeadersAfterForwardBecome: copyHashFlag].

	self initializeMemoryFirstFree: freeBlock. "re-initialize memory used for forwarding table"
	
	self forceInterruptCheck. "pretty much guaranteed to take a long time, so check for timers etc ASAP"

	^true "success"
]

{ #category : #allocation }
ObjectMemory >> bytesLeft: includingSwap [
	^(self sizeOfFree: freeBlock) "already commited"
		+ (self sqMemoryExtraBytesLeft: includingSwap).
]

{ #category : #'plugin support' }
ObjectMemory >> characterTable [
	^self splObj: CharacterTable
]

{ #category : #'memory access' }
ObjectMemory >> checkAddress: byteAddress [ 
	"Keep this method around for debugging the C code."
	byteAddress < self startOfMemory
		ifTrue: [self error: 'bad address: negative'].
	byteAddress >= memoryLimit
		ifTrue: [self error: 'bad address: past end of heap']
]

{ #category : #'memory access' }
ObjectMemory >> checkedByteAt: byteAddress [
	"Assumes zero-based array indexing."

	self checkAddress: byteAddress.
	^ self byteAt: byteAddress
]

{ #category : #'memory access' }
ObjectMemory >> checkedByteAt: byteAddress put: byte [
	"Assumes zero-based array indexing."

	self checkAddress: byteAddress.
	self byteAt: byteAddress put: byte.
]

{ #category : #'memory access' }
ObjectMemory >> checkedLongAt: byteAddress [
	"Assumes zero-based array indexing. For testing in Smalltalk, this method should be overridden in a subclass."

	self checkAddress: byteAddress.
	self checkAddress: byteAddress + 3.
	^ self longAt: byteAddress
]

{ #category : #'memory access' }
ObjectMemory >> checkedLongAt: byteAddress put: a32BitInteger [
	"Assumes zero-based array indexing. For testing in Smalltalk, this method should be overridden in a subclass."

	self checkAddress: byteAddress.
	self checkAddress: byteAddress + 3.
	self longAt: byteAddress put: a32BitInteger.
]

{ #category : #'oop/chunk conversion' }
ObjectMemory >> chunkFromOop: oop [
	"Compute the chunk of this oop by subtracting its extra header bytes."

	^ oop - (self extraHeaderBytes: oop)
]

{ #category : #'plugin support' }
ObjectMemory >> classArray [
	^self splObj: ClassArray
]

{ #category : #'plugin support' }
ObjectMemory >> classBitmap [
	^self splObj: ClassBitmap
]

{ #category : #'plugin support' }
ObjectMemory >> classByteArray [
	^self splObj: ClassByteArray
]

{ #category : #'plugin support' }
ObjectMemory >> classCharacter [
	^self splObj: ClassCharacter
]

{ #category : #'plugin support' }
ObjectMemory >> classExternalAddress [
	^self splObj: ClassExternalAddress
]

{ #category : #'plugin support' }
ObjectMemory >> classExternalData [
	^self splObj: ClassExternalData
]

{ #category : #'plugin support' }
ObjectMemory >> classExternalFunction [
	^self splObj: ClassExternalFunction
]

{ #category : #'plugin support' }
ObjectMemory >> classExternalLibrary [
	^self splObj: ClassExternalLibrary
]

{ #category : #'plugin support' }
ObjectMemory >> classExternalStructure [
	^self splObj: ClassExternalStructure
]

{ #category : #'plugin support' }
ObjectMemory >> classFloat [
	^self splObj: ClassFloat
]

{ #category : #'header access' }
ObjectMemory >> classHeader: oop [

	^ self longAt: oop - 4
]

{ #category : #'plugin support' }
ObjectMemory >> classLargeNegativeInteger [
	^self splObj: ClassLargeNegativeInteger
]

{ #category : #'plugin support' }
ObjectMemory >> classLargePositiveInteger [
	^self splObj: ClassLargePositiveInteger
]

{ #category : #'plugin support' }
ObjectMemory >> classPoint [
	^self splObj: ClassPoint
]

{ #category : #'plugin support' }
ObjectMemory >> classSemaphore [
	^self splObj: ClassSemaphore
]

{ #category : #'plugin support' }
ObjectMemory >> classSmallInteger [
	^self splObj: ClassInteger
]

{ #category : #'plugin support' }
ObjectMemory >> classString [
	^self splObj: ClassString
]

{ #category : #'garbage collection' }
ObjectMemory >> clearRootsTable [
	"Clear the root bits of the current roots, then empty the roots 
	table. "
	"Caution: This should only be done when the young object 
	space is empty."
	"reset the roots table (after this, all objects are old so there 
	are no roots)"
	| oop |
	1 to: rootTableCount do: [:i | 
			"clear root bits of current root table entries"
			oop _ rootTable at: i.
			self longAt: oop put: ((self longAt: oop) bitAnd: AllButRootBit).
			rootTable at: i put: 0].
	rootTableCount _ 0
]

{ #category : #allocation }
ObjectMemory >> clone: oop [
	"Return a shallow copy of the given object. May cause GC"
	"Assume: Oop is a real object, not a small integer."

	| extraHdrBytes bytes newChunk remappedOop fromIndex toIndex lastFrom newOop header hash |
	self inline: false.
	extraHdrBytes _ self extraHeaderBytes: oop.
	bytes _ self sizeBitsOf: oop.
	bytes _ bytes + extraHdrBytes.

	"allocate space for the copy, remapping oop in case of a GC"
	self pushRemappableOop: oop.
	newChunk _ self allocateChunk: bytes.
	remappedOop _ self popRemappableOop.

	"copy old to new including all header words"
	toIndex _ newChunk - 4.  "loop below uses pre-increment"
	fromIndex _ (remappedOop - extraHdrBytes) - 4.
	lastFrom _ fromIndex + bytes.
	[fromIndex < lastFrom] whileTrue: [
		self longAt: (toIndex _ toIndex + 4) put: (self longAt: (fromIndex _ fromIndex + 4))].
	newOop _ newChunk + extraHdrBytes.  "convert from chunk to oop"

	"fix base header: compute new hash and clear Mark and Root bits"
	hash _ self newObjectHash.
	header _ (self longAt: newOop) bitAnd: 16r1FFFF.
	"use old ccIndex, format, size, and header-type fields"
	header _ header bitOr: ((hash << 17) bitAnd: 16r1FFE0000).
	self longAt: newOop put: header.
	^newOop

]

{ #category : #become }
ObjectMemory >> containOnlyOops: array1 and: array2 [ 
	"Return true if neither array contains a small integer. You can't become: integers! Also check for attempt to make an object become itself which upsets the GC code"
	| fieldOffset oop1 oop2|
	fieldOffset _ self lastPointerOf: array1.
	"we have previously checked that array1 is same size as array2 - this code may crash the system otherwise"
	[fieldOffset >= BaseHeaderSize]
		whileTrue: [oop1 _ self longAt: array1 + fieldOffset.
			oop2 _ self longAt: array2 + fieldOffset.
			oop1 = oop2 ifTrue:[^false].
			(self isIntegerObject: oop1) ifTrue: [^ false].
			(self isIntegerObject: oop2) ifTrue: [^ false].
			fieldOffset _ fieldOffset - 4].
	^ true
]

{ #category : #'plugin support' }
ObjectMemory >> displayObject [
	^self splObj: TheDisplay
]

{ #category : #'oop/chunk conversion' }
ObjectMemory >> extraHeaderBytes: oopOrChunk [
	"Return the number of extra bytes used by the given object's header."
	"Warning: This method should not be used during marking, when the header type bits of an object may be incorrect."

	"JMM should be an array lookup!" 
	self inline: true.
	^ headerTypeBytes at: (self headerType: oopOrChunk).
]

{ #category : #'plugin support' }
ObjectMemory >> falseObject [
	^falseObj
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchByte: byteIndex ofObject: oop [

	^ self byteAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + byteIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchClassOf: oop [ 
	| ccIndex |
	self inline: true.
	(self isIntegerObject: oop) ifTrue: [^ self splObj: ClassInteger].

	ccIndex _ (self baseHeader: oop) >> 12 bitAnd: 31.
	ccIndex = 0
		ifTrue: [^ (self classHeader: oop)
				bitAnd: AllButTypeMask]
		ifFalse: ["look up compact class"
			^ self fetchPointer: ccIndex - 1 ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop)]
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchClassOfNonInt: oop [ 
	| ccIndex |
	self inline: true.
	ccIndex _ (self baseHeader: oop) >> 12 bitAnd: 31.
	ccIndex = 0
		ifTrue: [^ (self classHeader: oop)
				bitAnd: AllButTypeMask]
		ifFalse: ["look up compact class"
			^ self fetchPointer: ccIndex - 1 ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop)]
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchPointer: fieldIndex ofObject: oop [

	^ self longAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + (fieldIndex << 2)
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchWord: fieldIndex ofObject: oop [

	^ self longAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + (fieldIndex << 2)
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchWordLengthOf: objectPointer [

	| sz |
	sz _ self sizeBitsOf: objectPointer.
	^ (sz - BaseHeaderSize) >> 2
]

{ #category : #finalization }
ObjectMemory >> finalizeReference: oop [ 
	"During sweep phase we have encountered a weak reference. 
	Check if  its object has gone away (or is about to) and if so, signal a 
	semaphore. "
	"Do *not* inline this in sweepPhase - it is quite an unlikely 
	case to run into a weak reference"
	| weakOop oopGone chunk firstField lastField |
	self inline: false.
	firstField _ BaseHeaderSize + ((self nonWeakFieldsOf: oop) << 2).
	lastField _ self lastPointerOf: oop.
	firstField to: lastField by: 4 do: [:i | 
			weakOop _ self longAt: oop + i.
			(weakOop == nilObj or: [self isIntegerObject: weakOop])
				ifFalse: ["Check if the object is being collected. 
					If the weak reference points  
					* backward: check if the weakOops chunk is free
					* forward: check if the weakOoop has been marked by GC"
					weakOop < oop
						ifTrue: [chunk _ self chunkFromOop: weakOop.
							oopGone _ ((self longAt: chunk) bitAnd: TypeMask) = HeaderTypeFree]
						ifFalse: [oopGone _ ((self baseHeader: weakOop) bitAnd: MarkBit) = 0].
					oopGone ifTrue: ["Store nil in the pointer and signal the  interpreter "
							self longAt: oop + i put: nilObj.
							self signalFinalization: oop]]]
]

{ #category : #'object enumeration' }
ObjectMemory >> firstAccessibleObject [
	"Return the first accessible object in the heap."
	| obj |
	obj _ self firstObject.
	[obj < endOfMemory]
		whileTrue: [(self isFreeObject: obj) ifFalse: [^ obj].
			obj _ self objectAfter: obj].
	self error: 'heap is empty'
]

{ #category : #'object enumeration' }
ObjectMemory >> firstObject [
	"Return the first object or free chunk in the heap."

	^ self oopFromChunk: self startOfMemory
]

{ #category : #'header access' }
ObjectMemory >> formatOf: oop [
"       0      no fields
        1      fixed fields only (all containing pointers)
        2      indexable fields only (all containing pointers)
        3      both fixed and indexable fields (all containing pointers)
        4      both fixed and indexable weak fields (all containing pointers).

        5      unused
        6      indexable word fields only (no pointers)
        7      unused
 
    8-11      indexable byte fields only (no pointers) (low 2 bits are low 2 bits of size)
   12-15     compiled methods:
                   # of literal oops specified in method header,
                   followed by indexable bytes (same interpretation of low 2 bits as above)
"

	^ ((self baseHeader: oop) >> 8) bitAnd: 16rF
]

{ #category : #'garbage collection' }
ObjectMemory >> fullCompaction [
	"Move all accessible objects down to leave one big free chunk 
	at the end of memory."
	"Assume: Incremental GC has just been done to maximimize 
	forwarding table space."
	"need not move objects below the first free chunk"
	| sz |
	compStart _ self lowestFreeAfter: self startOfMemory.
	compStart = freeBlock
		ifTrue: ["memory is already compact; only free chunk is at the end "
			^ self initializeMemoryFirstFree: freeBlock].
	(sz _ self fwdTableSize: 8) < totalObjectCount
		ifTrue: ["Try to grow OM to make a single pass full GC"
			self growObjectMemory: totalObjectCount - sz + 10000 * 8].
	"work up through memory until all free space is at the end"
	[compStart < freeBlock]
		whileTrue: ["free chunk returned by incCompBody becomes start of next compaction"
			compStart _ self incCompBody]
]

{ #category : #'garbage collection' }
ObjectMemory >> fullGC [
	"Do a mark/sweep garbage collection of the entire object memory. Free inaccessible objects but do not move them."

	| startTime |
	self inline: false.
	DoAssertionChecks ifTrue: [self reverseDisplayFrom: 0 to: 7].
	self preGCAction: true.
	startTime _ self ioMicroMSecs.
	self clearRootsTable.
	youngStart _ self startOfMemory.  "process all of memory"
	self markPhase.
	"Sweep phase returns the number of survivors.
	Use the up-to-date version instead the one from startup."
	totalObjectCount _ self sweepPhase.
	self fullCompaction.
	allocationCount _ 0.
	statFullGCs _ statFullGCs + 1.
	statFullGCMSecs _ statFullGCMSecs + (self ioMicroMSecs - startTime).

	youngStart _ freeBlock.  "reset the young object boundary"
	self postGCAction.
	DoAssertionChecks ifTrue: [self reverseDisplayFrom: 0 to: 7].

]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdBlockGet: blkSize [
	"Return the address of a two- or four-word forwarding block or nil if no more entries are available."

	fwdTableNext _ fwdTableNext + blkSize.
	fwdTableNext <= fwdTableLast
		ifTrue: [ ^ fwdTableNext ]
		ifFalse: [ ^ nil ].  "no more forwarding blocks available"
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdBlockValidate: addr [
	"Raise an error if the given address is not a valid forward table entry."

	(( addr > endOfMemory) and:
	 [(addr <= fwdTableNext) and:
	 [(addr bitAnd: 3) = 0]])
		ifFalse: [ self error: 'invalid fwd table entry' ].
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdTableInit: blkSize [
	"Set the limits for a table of two- or three-word forwarding blocks above the last used oop. The pointer fwdTableNext moves up to fwdTableLast. Used for compaction of memory and become-ing objects. Returns the number of forwarding blocks available."

	self inline: false.
	"set endOfMemory to just after a minimum-sized free block"
	self setSizeOfFree: freeBlock to: BaseHeaderSize.
	endOfMemory _ freeBlock + BaseHeaderSize.

	"make a fake free chunk at endOfMemory for use as a sentinal in memory scans"
	self setSizeOfFree: endOfMemory to: BaseHeaderSize.

	"use all memory free between freeBlock and memoryLimit for forwarding table"
	"Note: Forward blocks must be quadword aligned."
	fwdTableNext _ (endOfMemory + BaseHeaderSize + 7) bitAnd: 16rFFFFFFF8.
	fwdTableLast _ memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdTableLast - fwdTableNext) // blkSize  "round down"
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdTableSize: blkSize [
	"Estimate the number of forwarding blocks available for compaction"
	| eom fwdFirst fwdLast |
	self inline: false.

	eom _ freeBlock + BaseHeaderSize.
	"use all memory free between freeBlock and memoryLimit for forwarding table"

	"Note: Forward blocks must be quadword aligned."
	fwdFirst _ (eom + BaseHeaderSize + 7) bitAnd: 16rFFFFFFF8.
	fwdLast _ memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdLast - fwdFirst) // blkSize  "round down"
]

{ #category : #allocation }
ObjectMemory >> growObjectMemory: delta [ 
	"Attempt to grow the object memory by the given delta 
	amount "
	| limit |
	limit _ self sqGrowMemory: memoryLimit By: delta.
	limit = memoryLimit
		ifFalse: [memoryLimit _ limit - 24.
			"remove a tad for safety"
			self initializeMemoryFirstFree: freeBlock]
]

{ #category : #'header access' }
ObjectMemory >> hashBitsOf: oop [

	^ ((self baseHeader: oop) >> 17) bitAnd: 16rFFF
]

{ #category : #'header access' }
ObjectMemory >> headerType: oop [

	^ (self longAt: oop) bitAnd: TypeMask
]

{ #category : #'gc -- compaction' }
ObjectMemory >> incCompBody [
	"Move objects to consolidate free space into one big chunk. Return the newly created free chunk."

	| bytesFreed |
	self inline: false.
	"reserve memory for forwarding table"
	self fwdTableInit: 8.  "Two-word blocks"

	"assign new oop locations, reverse their headers, and initialize forwarding blocks"
	bytesFreed _ self incCompMakeFwd.

	"update pointers to point at new oops"
	self mapPointersInObjectsFrom: youngStart to: endOfMemory.

	"move the objects and restore their original headers; return the new free chunk"
	^ self incCompMove: bytesFreed
]

{ #category : #'gc -- compaction' }
ObjectMemory >> incCompMakeFwd [
	"Create and initialize forwarding blocks for all non-free objects  
	following compStart. If the supply of forwarding blocks is exhausted,  
	set compEnd to the first chunk above the area to be 
	compacted; otherwise, set it to endOfMemory. Return the number of 
	bytes to be freed."
	| bytesFreed oop fwdBlock newOop |
	self inline: false.
	bytesFreed _ 0.
	oop _ self oopFromChunk: compStart.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifTrue: [bytesFreed _ bytesFreed + (self sizeOfFree: oop)]
				ifFalse: ["create a forwarding block for oop"
					fwdBlock _ self fwdBlockGet: 8.
					"Two-word block"
					fwdBlock = nil
						ifTrue: ["stop; we have used all available forwarding blocks"
							compEnd _ self chunkFromOop: oop.
							^ bytesFreed].
					newOop _ oop - bytesFreed.
					self initForwardBlock: fwdBlock mapping: oop to: newOop withBackPtr: false].
			oop _ self objectAfterWhileForwarding: oop].
	compEnd _ endOfMemory.
	^ bytesFreed
]

{ #category : #'gc -- compaction' }
ObjectMemory >> incCompMove: bytesFreed [ 
	"Move all non-free objects between compStart and compEnd to their new  
	locations, restoring their headers in the process. Create a new free  
	block at the end of memory. Return the newly created free chunk. "
	"Note: The free block used by the allocator always must be the last free  
	block in memory. It may take several compaction passes to make all  
	free space bubble up to the end of memory."
	| oop next fwdBlock newOop header bytesToMove firstWord lastWord newFreeChunk sz target |
	self inline: false.
	newOop _ nil.
	oop _ self oopFromChunk: compStart.
	[oop < compEnd]
		whileTrue: [next _ self objectAfterWhileForwarding: oop.
			(self isFreeObject: oop)
				ifFalse: ["a moving object; unwind its forwarding block"
					fwdBlock _ ((self longAt: oop) bitAnd: AllButMarkBitAndTypeMask) << 1.
					DoAssertionChecks
						ifTrue: [self fwdBlockValidate: fwdBlock].
					newOop _ self longAt: fwdBlock.
					header _ self longAt: fwdBlock + 4.
					self longAt: oop put: header. "restore the original header"
					bytesToMove _ oop - newOop. "move the oop (including any extra header words) "
					sz _ self sizeBitsOf: oop.
					firstWord _ oop - (self extraHeaderBytes: oop).
					lastWord _ oop + sz - BaseHeaderSize.
					target _ firstWord - bytesToMove.
					firstWord to: lastWord by: 4
						do: [:w | 
							self longAt: target put: (self longAt: w).
							target _ target + 4]].
			oop _ next].
	newOop = nil
		ifTrue: ["no objects moved"
			oop _ self oopFromChunk: compStart.
			((self isFreeObject: oop) and: [(self objectAfter: oop) = (self oopFromChunk: compEnd)])
				ifTrue: [newFreeChunk _ oop]
				ifFalse: [newFreeChunk _ freeBlock]]
		ifFalse: ["initialize the newly freed memory chunk"
			"newOop is the last object moved; free chunk starts 
			right after it"
			newFreeChunk _ newOop + (self sizeBitsOf: newOop).
			self setSizeOfFree: newFreeChunk to: bytesFreed].
	DoAssertionChecks
		ifTrue: [(self objectAfter: newFreeChunk) = (self oopFromChunk: compEnd)
				ifFalse: [self error: 'problem creating free chunk after compaction']].
	(self objectAfter: newFreeChunk) = endOfMemory
		ifTrue: [self initializeMemoryFirstFree: newFreeChunk]
		ifFalse: ["newFreeChunk is not at end of memory; re-install freeBlock "
			self initializeMemoryFirstFree: freeBlock].
	^ newFreeChunk
]

{ #category : #'garbage collection' }
ObjectMemory >> incrementalCompaction [
	"Move objects down to make one big free chunk. Compact the 
	last N objects (where N = number of forwarding table 
	entries) of the young object area."
	"Assume: compStart was set during the sweep phase"
	compStart = freeBlock
		ifTrue: ["Note: If compStart = freeBlock then either the young 
			space is already compact  or there are enough forwarding table entries to do a 
			one-pass incr. compaction."
			self initializeMemoryFirstFree: freeBlock]
		ifFalse: [self incCompBody]
]

{ #category : #'garbage collection' }
ObjectMemory >> incrementalGC [
	"Do a mark/sweep garbage collection of just the young object 
	area of object memory (i.e., objects above youngStart), using 
	the root table to identify objects containing pointers to 
	young objects from the old object area."
	| survivorCount startTime |
	self inline: false.
	rootTableCount >= RootTableSize
		ifTrue: ["root table overflow; cannot do an incremental GC (this should be very rare)"
			statRootTableOverflows _ statRootTableOverflows + 1.
			^ self fullGC].
	DoAssertionChecks
		ifTrue: [self reverseDisplayFrom: 8 to: 15.
			self validateRoots].

	self preGCAction: false.
	"incremental GC and compaction"

	startTime _ self ioMicroMSecs.
	self markPhase.
	survivorCount _ self sweepPhase.
	self incrementalCompaction.
	allocationCount _ 0.
	statIncrGCs _ statIncrGCs + 1.
	statIncrGCMSecs _ statIncrGCMSecs + (self ioMicroMSecs - startTime).

	self forceInterruptCheck. "Force an an interrupt check ASAP.We could choose to be clever here and only do this under certain time conditions. Keep it simple for now"
	
	(survivorCount > tenuringThreshold
			or: [rootTableCount >= RootTableRedZone])
		ifTrue: ["move up the young space boundary if 
			* there are too many survivors: 
			this limits the number of objects that must be 
			processed on future incremental GC's 
			* we're about to overflow the roots table 
			this limits the number of full GCs that may be caused 
			by root table overflows in the near future"
			statTenures _ statTenures + 1.
			self clearRootsTable.
			youngStart _ freeBlock].
	self postGCAction.
	DoAssertionChecks
		ifTrue: [self reverseDisplayFrom: 8 to: 15]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> initForwardBlock: fwdBlock mapping: oop to: newOop withBackPtr: backFlag [ 
	"Initialize the given forwarding block to map oop to newOop, 
	and replace oop's header with a pointer to the fowarding 
	block. "
	"Details: The mark bit is used to indicate that an oop is 
	forwarded. When an oop is forwarded, its header (minus the 
	mark bit) contains the address of its forwarding block. (The 
	forwarding block address is actually shifted right by one bit 
	so that its top-most bit does not conflict with the header's 
	mark bit; since fowarding blocks are stored on word 
	boundaries, the low two bits of the address are always zero.) 
	The first word of the forwarding block is the new oop; the 
	second word is the oop's orginal header. In the case of a 
	forward become, a four-word block is used, with the third 
	field being a backpointer to the old oop (for header fixup), 
	and the fourth word is unused. The type bits of the 
	forwarding header are the same as those of the original 
	header. "
	| originalHeader originalHeaderType |
	self inline: true.
	originalHeader _ self longAt: oop.
	DoAssertionChecks
		ifTrue: [fwdBlock = nil ifTrue: [self error: 'ran out of forwarding blocks in become'].
			(originalHeader bitAnd: MarkBit) ~= 0
				ifTrue: [self error: 'object already has a forwarding table entry']].
	originalHeaderType _ originalHeader bitAnd: TypeMask.
	self longAt: fwdBlock put: newOop.
	self longAt: fwdBlock + 4 put: originalHeader.
	backFlag ifTrue: [self longAt: fwdBlock + 8 put: oop].
	self longAt: oop put: (fwdBlock >> 1 bitOr: (MarkBit bitOr: originalHeaderType))
]

{ #category : #'object enumeration' }
ObjectMemory >> initialInstanceOf: classPointer [ 
	"Support for instance enumeration. Return the first instance 
	of the given class, or nilObj if it has no instances."
	| thisObj thisClass |
	thisObj _ self firstAccessibleObject.
	[thisObj = nil]
		whileFalse: [thisClass _ self fetchClassOf: thisObj.
			thisClass = classPointer ifTrue: [^ thisObj].
			thisObj _ self accessibleObjectAfter: thisObj].
	^ nilObj
]

{ #category : #initialization }
ObjectMemory >> initializeMemoryFirstFree: firstFree [ 
	"Initialize endOfMemory to the top of oop storage space, reserving some space for forwarding blocks, and create the freeBlock from which space is allocated. Also create a fake free chunk at endOfMemory to act as a sentinal for memory scans. "
	"Note: The amount of space reserved for forwarding blocks should be chosen to ensure that incremental compactions can usually be done in a single pass. However, there should be enough forwarding blocks so a full compaction can be done in a reasonable number of passes, say ten. (A full compaction requires N object-moving passes, where N = number of non-garbage objects / number of forwarding blocks). 
	di 11/18/2000 Re totalObjectCount: Provide a margin of one byte per object to be used for forwarding pointers at GC time. Since fwd blocks are 8 bytes, this means an absolute worst case of 8 passes to compact memory. In most cases it will be adequate to do compaction in a single pass. "
	| fwdBlockBytes |
	"reserve space for forwarding blocks"
	fwdBlockBytes _ totalObjectCount bitAnd: 4294967292.
	memoryLimit - fwdBlockBytes >= (firstFree + BaseHeaderSize)
		ifFalse: ["reserve enough space for a minimal free block of BaseHeaderSize bytes"
			fwdBlockBytes _ memoryLimit - (firstFree + BaseHeaderSize)].

	"set endOfMemory and initialize freeBlock"
	endOfMemory _ memoryLimit - fwdBlockBytes.
	freeBlock _ firstFree.
	self setSizeOfFree: freeBlock to: endOfMemory - firstFree. "bytes available for oops"

	"make a fake free chunk at endOfMemory for use as a sentinel in memory scans"
	self setSizeOfFree: endOfMemory to: BaseHeaderSize.
	DoAssertionChecks
		ifTrue: [(freeBlock < endOfMemory and: [endOfMemory < memoryLimit])
				ifFalse: [self error: 'error in free space computation'].
			(self oopFromChunk: endOfMemory) = endOfMemory
				ifFalse: [self error: 'header format must have changed'].
			(self objectAfter: freeBlock) = endOfMemory
				ifFalse: [self error: 'free block not properly initialized']]
]

{ #category : #initialization }
ObjectMemory >> initializeObjectMemory: bytesToShift [
	"Initialize object memory variables at startup time. Assume endOfMemory is initially set (by the image-reading code) to the end of the last object in the image. Initialization redefines endOfMemory to be the end of the object allocation area based on the total available memory, but reserving some space for forwarding blocks."
	"Assume: image reader initializes the following variables:
		memory
		endOfMemory
		memoryLimit
		specialObjectsOop
		lastHash
	"
	"di 11/18/2000 fix slow full GC"
	self inline: false.

	"set the start of the young object space"
	youngStart _ endOfMemory.

	"image may be at a different address; adjust oops for new location"
	totalObjectCount _ self adjustAllOopsBy: bytesToShift.

	self initializeMemoryFirstFree: endOfMemory. "initializes endOfMemory, freeBlock"

	specialObjectsOop _ specialObjectsOop + bytesToShift.

	"heavily used special objects"
	nilObj	_ self splObj: NilObject.
	falseObj	_ self splObj: FalseObject.
	trueObj	_ self splObj: TrueObject.

	rootTableCount _ 0.
	freeContexts _ NilContext.
	freeLargeContexts _ NilContext.
	allocationCount _ 0.
	lowSpaceThreshold _ 0.
	signalLowSpace _ false.
	compStart _ 0.
	compEnd _ 0.
	fwdTableNext _ 0.
	fwdTableLast _ 0.
	remapBufferCount _ 0.
	allocationsBetweenGCs _ 4000.  "do incremental GC after this many allocations"
	tenuringThreshold _ 2000.  "tenure all suriving objects if count is over this threshold"
	growHeadroom _ 4*1024*1024. "four megabyte of headroom when growing"
	shrinkThreshold _ 8*1024*1024. "eight megabyte of free space before shrinking"

	"garbage collection statistics"
	statFullGCs _ 0.
	statFullGCMSecs _ 0.
	statIncrGCs _ 0.
	statIncrGCMSecs _ 0.
	statTenures _ 0.
	statRootTableOverflows _ 0.

]

{ #category : #'object enumeration' }
ObjectMemory >> instanceAfter: objectPointer [ 
	"Support for instance enumeration. Return the next instance 
	of the class of the given object, or nilObj if the enumeration 
	is complete."
	| classPointer thisObj thisClass |
	classPointer _ self fetchClassOf: objectPointer.
	thisObj _ self accessibleObjectAfter: objectPointer.
	[thisObj = nil]
		whileFalse: [thisClass _ self fetchClassOf: thisObj.
			thisClass = classPointer ifTrue: [^ thisObj].
			thisObj _ self accessibleObjectAfter: thisObj].
	^ nilObj
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateClass: classPointer indexableSize: size [ 
	" 
	NOTE: This method supports the backward-compatible split instSize field of the 
	class format word. The sizeHiBits will go away and other shifts change by 2 
	when the split fields get merged in an (incompatible) image change. "
	| hash header1 header2 cClass byteSize format inc binc header3 hdrSize fillWord newObj sizeHiBits |
	self inline: false.
	DoAssertionChecks ifTrue: [size < 0
				ifTrue: [self error: 'cannot have a negative indexable field count']].
	hash _ self newObjectHash.
	header1 _ self formatOfClass: classPointer.
	"Low 2 bits are 0"
	sizeHiBits _ (header1 bitAnd: 393216) >> 9.
	header1 _ (header1 bitAnd: 131071) bitOr: (hash << HashBitsOffset bitAnd: HashBits).
	header2 _ classPointer.
	header3 _ 0.
	cClass _ header1 bitAnd: CompactClassMask. "compact class field from format word"
	byteSize _ (header1 bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"
	format _ header1 >> 8 bitAnd: 15.
	format < 8
		ifTrue: ["Bitmaps and Arrays"
			inc _ size * 4]
		ifFalse: ["Strings and Methods"
			inc _ size + 3 bitAnd: AllButTypeMask. "round up"
			binc _ 3 - (size + 3 bitAnd: 3). "odd bytes"
			"low bits of byte size go in format field"
			header1 _ header1 bitOr: binc << 8].
	byteSize + inc > 255
		ifTrue: ["requires size header word"
			header3 _ byteSize + inc.
			header1 _ header1 - (byteSize bitAnd: 255)]
		ifFalse: [header1 _ header1 + inc].
	byteSize _ byteSize + inc.
	header3 > 0
		ifTrue: ["requires full header"
			hdrSize _ 3]
		ifFalse: [cClass = 0
				ifTrue: [hdrSize _ 2]
				ifFalse: [hdrSize _ 1]].
	format <= 4
		ifTrue: ["if pointers, fill with nil oop"
			fillWord _ nilObj]
		ifFalse: [fillWord _ 0].
	newObj _ self allocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3 doFill: true with: fillWord.
	^ newObj
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateContext: classPointer sizeInBytes: sizeInBytes [ 
	"This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word."
	| hash header1 header2 hdrSize |
	hash _ self newObjectHash.
	header1 _ (hash << HashBitsOffset bitAnd: HashBits) bitOr: (self formatOfClass: classPointer).
	header1 _ header1 + (sizeInBytes - (header1 bitAnd: SizeMask)).
	header2 _ classPointer.
	(header1 bitAnd: CompactClassMask) = 0
		ifTrue: ["is compact class field from format word zero?"
			hdrSize _ 2]
		ifFalse: [hdrSize _ 1].
	^ self allocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: 0 doFill: false with: 0
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateSmallClass: classPointer sizeInBytes: sizeInBytes fill: fillValue [ 
	"This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word. 
	May cause a GC"
	| hash header1 header2 hdrSize |
	hash _ self newObjectHash.
	header1 _ (hash << HashBitsOffset bitAnd: HashBits) bitOr: (self formatOfClass: classPointer).
	header1 _ header1 + (sizeInBytes - (header1 bitAnd: SizeMask)).
	header2 _ classPointer.
	(header1 bitAnd: CompactClassMask) = 0
		ifTrue: ["is compact class field from format word zero?"
			hdrSize _ 2]
		ifFalse: [hdrSize _ 1].
	^ self allocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: 0 doFill: true with: fillValue
]

{ #category : #'interpreter access' }
ObjectMemory >> integerObjectOf: value [
	value < 0
		ifTrue: [^ ((16r80000000 + value) << 1) + 1]
		ifFalse: [^ (value << 1) + 1]
]

{ #category : #'interpreter access' }
ObjectMemory >> integerValueOf: objectPointer [
	"Translator produces 'objectPointer >> 1'"

	((objectPointer bitAnd: 16r80000000) ~= 0)
		ifTrue: ["negative"
				^ ((objectPointer bitAnd: 16r7FFFFFFF) >> 1)
					- 16r3FFFFFFF - 1  "Faster than -16r40000000 (a LgInt)"]
		ifFalse: ["positive"
				^ objectPointer >> 1]
]

{ #category : #'header access' }
ObjectMemory >> isArray: oop [
	"Answer true if this is an indexable object with pointer elements, e.g., an array"
	^(self isNonIntegerObject: oop) and:[self isArrayNonInt: oop]
]

{ #category : #'header access' }
ObjectMemory >> isArrayNonInt: oop [
	"Answer true if this is an indexable object with pointer elements, e.g., an array"
	^ (self formatOf: oop) = 2
]

{ #category : #'header access' }
ObjectMemory >> isBytes: oop [
	"Answer true if the argument contains indexable bytes. See comment in formatOf:"
	"Note: Includes CompiledMethods."
	^(self isNonIntegerObject: oop) and:[self isBytesNonInt: oop]
]

{ #category : #'header access' }
ObjectMemory >> isBytesNonInt: oop [
	"Answer true if the argument contains indexable bytes. See comment in formatOf:"
	"Note: Includes CompiledMethods."

	^ (self formatOf: oop)  >= 8
]

{ #category : #'interpreter access' }
ObjectMemory >> isCompiledMethod: oop [
    "Answer whether the receiver is of compiled method format"
    ^(self formatOf: oop) >= 12

]

{ #category : #'header access' }
ObjectMemory >> isFreeObject: oop [

	^ (self headerType: oop) = HeaderTypeFree
]

{ #category : #'plugin support' }
ObjectMemory >> isInMemory: address [
	"Return true if the given address is in ST object memory"
	^address >= self startOfMemory and:[address < endOfMemory]
]

{ #category : #'interpreter access' }
ObjectMemory >> isIntegerObject: objectPointer [

	^ (objectPointer bitAnd: 1) > 0
]

{ #category : #'interpreter access' }
ObjectMemory >> isIntegerValue: intValue [
	"Return true if the given value can be represented as a Smalltalk integer value."
	"Details: This trick is from Tim Rowledge. Use a shift and XOR to set the sign bit if and only if the top two bits of the given value are the same, then test the sign bit. Note that the top two bits are equal for exactly those integers in the range that can be represented in 31-bits."

	^ (intValue bitXor: (intValue << 1)) >= 0
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonIntegerObject: objectPointer [

	^ (objectPointer bitAnd: 1) = 0
]

{ #category : #'gc -- compaction' }
ObjectMemory >> isObjectForwarded: oop [ 
	"Return true if the given object has a forwarding table entry 
	during a compaction or become operation."
	^ (oop bitAnd: 1) = 0 and: ["(isIntegerObject: oop) not" ((self longAt: oop) bitAnd: MarkBit) ~= 0]
]

{ #category : #'header access' }
ObjectMemory >> isPointers: oop [
	"Answer true if the argument has only fields that can hold oops. See comment in formatOf:"

	^(self isNonIntegerObject: oop) and:[self isPointersNonInt: oop]
]

{ #category : #'header access' }
ObjectMemory >> isPointersNonInt: oop [
	"Answer true if the argument has only fields that can hold oops. See comment in formatOf:"

	^ (self formatOf: oop) <= 4
]

{ #category : #'header access' }
ObjectMemory >> isWeak: oop [
	"Answer true if the argument has only weak fields that can hold oops. See comment in formatOf:"
	^(self isNonIntegerObject: oop) and:[self isWeakNonInt: oop]
]

{ #category : #'header access' }
ObjectMemory >> isWeakNonInt: oop [
	"Answer true if the argument has only weak fields that can hold oops. See comment in formatOf:"
	^ (self formatOf: oop) = 4
]

{ #category : #'header access' }
ObjectMemory >> isWords: oop [
	"Answer true if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self isNonIntegerObject: oop) and:[self isWordsNonInt: oop]
]

{ #category : #'header access' }
ObjectMemory >> isWordsNonInt: oop [
	"Answer true if the argument contains only indexable words (no oops). See comment in formatOf:"

	^ (self formatOf: oop) = 6
]

{ #category : #'header access' }
ObjectMemory >> isWordsOrBytes: oop [
	"Answer true if the contains only indexable words or bytes (no oops). See comment in formatOf:"
	"Note: Excludes CompiledMethods."
	^(self isNonIntegerObject: oop) and:[self isWordsOrBytesNonInt: oop]
]

{ #category : #'header access' }
ObjectMemory >> isWordsOrBytesNonInt: oop [
	"Answer true if the contains only indexable words or bytes (no oops). See comment in formatOf:"
	"Note: Excludes CompiledMethods."

	| fmt |
	fmt _ self formatOf: oop.
	^ fmt = 6 or: [(fmt >= 8) and: [fmt <= 11]]
]

{ #category : #'object enumeration' }
ObjectMemory >> lastPointerOf: oop [ 
	"Return the byte offset of the last pointer field of the given object.  
	Works with CompiledMethods, as well as ordinary objects. 
	Can be used even when the type bits are not correct."
	| fmt sz methodHeader header contextSize |
	self inline: true.
	header _ self baseHeader: oop.
	fmt _ header >> 8 bitAnd: 15.
	fmt <= 4 ifTrue: [(fmt = 3 and: [self isContextHeader: header])
					ifTrue: ["contexts end at the stack pointer"
						contextSize _ self fetchStackPointerOf: oop.
						^ CtxtTempFrameStart + contextSize * 4].
				sz _ self sizeBitsOfSafe: oop.
				^ sz - BaseHeaderSize"all pointers"].
	fmt < 12 ifTrue: [^ 0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	methodHeader _ self longAt: oop + BaseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * 4 + BaseHeaderSize
]

{ #category : #'gc -- compaction' }
ObjectMemory >> lastPointerWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	the offset of the last pointer in the object in spite of this obstacle. "
	| header fwdBlock fmt size methodHeader contextSize |
	self inline: true.
	header _ self longAt: oop.
	(header bitAnd: MarkBit) ~= 0
		ifTrue: ["oop is forwarded; get its real header from its forwarding table entry"
			fwdBlock _ (header bitAnd: AllButMarkBitAndTypeMask) << 1.
			DoAssertionChecks
				ifTrue: [self fwdBlockValidate: fwdBlock].
			header _ self longAt: fwdBlock + 4].
	fmt _ header >> 8 bitAnd: 15.
	fmt <= 4
		ifTrue: [(fmt = 3 and: [self isContextHeader: header])
				ifTrue: ["contexts end at the stack pointer"
					contextSize _ self fetchStackPointerOf: oop.
					^ CtxtTempFrameStart + contextSize * 4].
			"do sizeBitsOf: using the header we obtained"
			(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
				ifTrue: [size _ (self sizeHeader: oop) bitAnd: AllButTypeMask]
				ifFalse: [size _ header bitAnd: SizeMask].
			^ size - BaseHeaderSize].
	fmt < 12 ifTrue: [^ 0]. "no pointers"
	methodHeader _ self longAt: oop + BaseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * 4 + BaseHeaderSize
]

{ #category : #'garbage collection' }
ObjectMemory >> lowestFreeAfter: chunk [ 
	"Return the first free block after the given chunk in memory."
	| oop oopHeader oopHeaderType oopSize |
	self inline: false.
	oop _ self oopFromChunk: chunk.
	[oop < endOfMemory]
		whileTrue: [oopHeader _ self baseHeader: oop.
			oopHeaderType _ oopHeader bitAnd: TypeMask.
			oopHeaderType = HeaderTypeFree
				ifTrue: [^ oop]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize _ (self sizeHeader: oop) bitAnd: AllButTypeMask]
						ifFalse: [oopSize _ oopHeader bitAnd: SizeMask]].
			oop _ self oopFromChunk: oop + oopSize].
	self error: 'expected to find at least one free object'
]

{ #category : #'gc -- compaction' }
ObjectMemory >> mapPointersInObjectsFrom: memStart to: memEnd [
	"Use the forwarding table to update the pointers of all non-free objects in the given range of memory. Also remap pointers in root objects which may contains pointers into the given memory range, and don't forget to flush the method cache based on the range"

	self inline: false.
	self compilerMapHookFrom: memStart to: memEnd.
	"update interpreter variables"
	self mapInterpreterOops.
	self flushMethodCacheFrom: memStart to: memEnd.
	self updatePointersInRootObjectsFrom: memStart to: memEnd.
	self updatePointersInRangeFrom: memStart to: memEnd.

]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> markAndTrace: oop [
	"Mark all objects reachable from the given one.
	Trace from the given object even if it is old.
	Do not trace if it is already marked.
	Mark it only if it is a young object."
	"Tracer state variables:
		child		object being examined
		field		next field of child to examine
		parentField	field where child was stored in its referencing object"

	| header lastFieldOffset action |
	header _ self longAt: oop.
	(header bitAnd: MarkBit) = 0 ifFalse: [^ 0  "already marked"].

	"record tracing status in object's header"
	header _ (header bitAnd: AllButTypeMask) bitOr: HeaderTypeGC.
	oop >= youngStart ifTrue: [ header _ header bitOr: MarkBit ].  "mark only if young"
	self longAt: oop put: header.

	"initialize the tracer state machine"
	parentField _ GCTopMarker.
	child _ oop.
	lastFieldOffset _ self lastPointerOf: oop.
	field _ oop + lastFieldOffset.
	action _ StartField.
	youngStartLocal _ youngStart.
	"run the tracer state machine until all objects reachable from oop are marked"
	[action = Done] whileFalse: [
		action = StartField ifTrue: [ action _ self startField ].
		action = StartObj ifTrue: [ action _ self startObj ].
		action = Upward ifTrue: [ action _ self upward ].
	].
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> markPhase [
	"Mark phase of the mark and sweep garbage collector. Set 
	the mark bits of all reachable objects. Free chunks are 
	untouched by this process."
	"Assume: All non-free objects are initially unmarked. Root 
	objects were unmarked when they were made roots. (Make 
	sure this stays true!!)."
	| oop |
	self inline: false.
	"clear the recycled context lists"
	freeContexts _ NilContext.
	freeLargeContexts _ NilContext.
	"trace the interpreter's objects, including the active stack 
	and special objects array"
	self markAndTraceInterpreterOops.
	"trace the roots"
	1 to: rootTableCount do: [:i | 
			oop _ rootTable at: i.
			self markAndTrace: oop]
]

{ #category : #'header access' }
ObjectMemory >> newObjectHash [
	"Answer a new 16-bit pseudo-random number for use as an identity hash."

	lastHash _ 13849 + (27181 * lastHash) bitAnd: 65535.
	^ lastHash

]

{ #category : #'interpreter access' }
ObjectMemory >> nilObject [
	"For access from BitBlt module"
	^ nilObj
]

{ #category : #'garbage collection' }
ObjectMemory >> noteAsRoot: oop headerLoc: headerLoc [ 
	"Record that the given oop in the old object area points to an 
	object in the young area. 
	HeaderLoc is usually = oop, but may be an addr in a 
	forwarding block."
	| header |
	self inline: true.
	header _ self longAt: headerLoc.
	(header bitAnd: RootBit) = 0
		ifTrue: ["record oop as root only if not already recorded"
			rootTableCount < RootTableRedZone
				ifTrue: ["record root if there is enough room in the roots 
					table "
					rootTableCount _ rootTableCount + 1.
					rootTable at: rootTableCount put: oop.
					self longAt: headerLoc put: (header bitOr: RootBit)]
				ifFalse: ["we're getting in the red zone"
					rootTableCount < RootTableSize
						ifTrue: ["but there's still space to record it"
							rootTableCount _ rootTableCount + 1.
							rootTable at: rootTableCount put: oop.
							self longAt: headerLoc put: (header bitOr: RootBit).
							"but force an IGC on the next allocation"
							allocationCount _ allocationsBetweenGCs + 1]]]
]

{ #category : #'object enumeration' }
ObjectMemory >> objectAfter: oop [ 
	"Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete."
	| sz |
	self inline: true.
	DoAssertionChecks
		ifTrue: [oop >= endOfMemory ifTrue: [self error: 'no objects after the end of memory']].
	(self isFreeObject: oop)
		ifTrue: [sz _ self sizeOfFree: oop]
		ifFalse: [sz _ self sizeBitsOf: oop].
	^ self oopFromChunk: oop + sz
]

{ #category : #'gc -- compaction' }
ObjectMemory >> objectAfterWhileForwarding: oop [
	"Return the oop of the object after the given oop when the actual header of the oop may be in the forwarding table."

	| header fwdBlock realHeader sz |
	self inline: true.
	header _ self longAt: oop.
	(header bitAnd: MarkBit) = 0 ifTrue: [ ^ self objectAfter: oop ].  "oop not forwarded"

	"Assume: mark bit cannot be set on a free chunk, so if we get here,
	 oop is not free and it has a forwarding table entry"

	fwdBlock _ (header bitAnd: AllButMarkBitAndTypeMask) << 1.
	DoAssertionChecks ifTrue: [ self fwdBlockValidate: fwdBlock ].
	realHeader _ self longAt: fwdBlock + 4.
	"following code is like sizeBitsOf:"
	(realHeader bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz _ (self sizeHeader: oop) bitAnd: AllButTypeMask ]
		ifFalse: [ sz _ realHeader bitAnd: SizeMask ].

	^ self oopFromChunk: (oop + sz)
]

{ #category : #'oop/chunk conversion' }
ObjectMemory >> oopFromChunk: chunk [
	"Compute the oop of this chunk by adding its extra header bytes."

	^ chunk + (self extraHeaderBytes: chunk)
]

{ #category : #'interpreter access' }
ObjectMemory >> popRemappableOop [
	"Pop and return the possibly remapped object from the remap buffer."

	| oop |
	oop _ remapBuffer at: remapBufferCount.
	remapBufferCount _ remapBufferCount - 1.
	^ oop
]

{ #category : #'garbage collection' }
ObjectMemory >> possibleRootStoreInto: oop value: valueObj [
	"oop is an old object.  If valueObj is young, mark the object as a root."

	self inline: false.
	((valueObj >= youngStart) and: [(self isIntegerObject: valueObj) not]) ifTrue:
		["Yes, valueObj is a young object"
		self noteAsRoot: oop headerLoc: oop].
]

{ #category : #become }
ObjectMemory >> prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag [ 
	"Ensure that there are enough forwarding blocks to 
	accomodate this become, then prepare forwarding blocks for 
	the pointer swap. Return true if successful."
	"Details: Doing a GC might generate enough space for 
	forwarding blocks if we're short. However, this is an 
	uncommon enough case that it is better handled by primitive 
	fail code at the Smalltalk level."
	| entriesNeeded entriesAvailable fieldOffset oop1 oop2 fwdBlock fwdBlkSize |
	entriesNeeded _ (self lastPointerOf: array1)
				// 4.
	"need enough entries for all oops"
	twoWayFlag
		ifTrue: ["Double the number of blocks for two-way become"
			entriesNeeded _ entriesNeeded * 2.
			fwdBlkSize _ 8
			"Note: Forward blocks must be quadword aligned."]
		ifFalse: ["One-way become needs backPointers in fwd blocks."
			fwdBlkSize _ 16
			"Note: Forward blocks must be quadword aligned."].
	entriesAvailable _ self fwdTableInit: fwdBlkSize.
	entriesAvailable < entriesNeeded
		ifTrue: [self initializeMemoryFirstFree: freeBlock.
			"re-initialize the free block"
			^ false].
	fieldOffset _ self lastPointerOf: array1.
	[fieldOffset >= BaseHeaderSize]
		whileTrue: [oop1 _ self longAt: array1 + fieldOffset.
			oop2 _ self longAt: array2 + fieldOffset.
			fwdBlock _ self fwdBlockGet: fwdBlkSize.
			self initForwardBlock: fwdBlock mapping: oop1 to: oop2 withBackPtr: twoWayFlag not.
			twoWayFlag
				ifTrue: ["Second block maps oop2 back to oop1 for two-way become"
					fwdBlock _ self fwdBlockGet: fwdBlkSize.
					self initForwardBlock: fwdBlock mapping: oop2 to: oop1 withBackPtr: twoWayFlag not].
			fieldOffset _ fieldOffset - 4].
	^ true
]

{ #category : #'interpreter access' }
ObjectMemory >> pushRemappableOop: oop [
	"Record the given object in a the remap buffer. Objects in this buffer are remapped when a compaction occurs. This facility is used by the interpreter to ensure that objects in temporary variables are properly remapped."

	remapBuffer at: (remapBufferCount _ remapBufferCount + 1) put: oop.
]

{ #category : #allocation }
ObjectMemory >> recycleContextIfPossible: cntxOop [ 
	"If possible, save the given context on a list of free contexts to 
	be recycled."
	"Note: The context is not marked free, so it can be reused 
	with minimal fuss. The recycled context lists are cleared at 
	every garbage collect."
	| header |
	self inline: true.
	"only recycle young contexts (which should be most of them)"
	cntxOop >= youngStart
		ifTrue: [header _ self baseHeader: cntxOop.
			(self isMethodContextHeader: header)
				ifTrue: ["It's a young context, alright."
					(header bitAnd: SizeMask) = SmallContextSize
						ifTrue: ["Recycle small contexts"
							self storePointerUnchecked: 0 ofObject: cntxOop withValue: freeContexts.
							freeContexts _ cntxOop].
					(header bitAnd: SizeMask) = LargeContextSize
						ifTrue: ["Recycle large contexts"
							self storePointerUnchecked: 0 ofObject: cntxOop withValue: freeLargeContexts.
							freeLargeContexts _ cntxOop]]]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remap: oop [ 
	"Map the given oop to its new value during a compaction or 
	become: operation. If it has no forwarding table entry, 
	return the oop itself."
	| fwdBlock |
	self inline: false.
	(self isObjectForwarded: oop)
		ifTrue: ["get the new value for oop from its forwarding block"
			fwdBlock _ ((self longAt: oop) bitAnd: AllButMarkBitAndTypeMask) << 1.
			DoAssertionChecks
				ifTrue: [self fwdBlockValidate: fwdBlock].
			^ self longAt: fwdBlock].
	^ oop
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remapClassOf: oop [ 
	"Update the class of the given object, if necessary, using its forwarding table entry."
	"Note: Compact classes need not be remapped since the compact class field is just an index into the compact class 
	table. The header type bits show if this object has a compact class; we needn't look up the oop's real header."
	| classHeader classOop fwdBlock newClassOop newClassHeader |
	(self headerType: oop) = HeaderTypeShort ifTrue: [^ nil]. "compact classes needn't be mapped"

	classHeader _ self longAt: oop - 4.
	classOop _ classHeader bitAnd: AllButTypeMask.
	(self isObjectForwarded: classOop)
		ifTrue: [fwdBlock _ ((self longAt: classOop) bitAnd: AllButMarkBitAndTypeMask) << 1.
			DoAssertionChecks
				ifTrue: [self fwdBlockValidate: fwdBlock].
			newClassOop _ self longAt: fwdBlock.
			newClassHeader _ newClassOop bitOr: (classHeader bitAnd: TypeMask).
			self longAt: oop - 4 put: newClassHeader.
			"The following ensures that become: into an old object's class makes it a root. 
			It does nothing during either incremental or full compaction because 
			oop will never be < youngStart."
			(oop < youngStart and: [newClassOop >= youngStart])
				ifTrue: [self beRootWhileForwarding: oop]]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remapFieldsAndClassOf: oop [ 
	"Replace all forwarded pointers in this object with their new oops, using the forwarding table. Remap its class as well, if 
	necessary. "
	"Note: The given oop may be forwarded itself, which means that its real header is in its forwarding table entry."
	| fieldOffset fieldOop fwdBlock newOop |
	self inline: true.
	fieldOffset _ self lastPointerWhileForwarding: oop.
	[fieldOffset >= BaseHeaderSize]
		whileTrue: [fieldOop _ self longAt: oop + fieldOffset.
			(self isObjectForwarded: fieldOop)
				ifTrue: ["update this oop from its forwarding block"
					fwdBlock _ ((self longAt: fieldOop) bitAnd: AllButMarkBitAndTypeMask) << 1.
					DoAssertionChecks
						ifTrue: [self fwdBlockValidate: fwdBlock].
					newOop _ self longAt: fwdBlock.
					self longAt: oop + fieldOffset put: newOop.
					"The following ensures that become: into old object makes it a root. 
					It does nothing during either incremental or full compaction because 
					oop will never be < youngStart."
					(oop < youngStart and: [newOop >= youngStart])
						ifTrue: [self beRootWhileForwarding: oop]].
			fieldOffset _ fieldOffset - 4].
	self remapClassOf: oop
]

{ #category : #become }
ObjectMemory >> restoreHeaderOf: oop [ 
	"Restore the original header of the given oop from its 
	forwarding block."
	| fwdHeader fwdBlock |
	fwdHeader _ self longAt: oop.
	fwdBlock _ (fwdHeader bitAnd: AllButMarkBitAndTypeMask) << 1.
	DoAssertionChecks
		ifTrue: [(fwdHeader bitAnd: MarkBit) = 0
				ifTrue: [self error: 'attempting to restore the header of an object that has no forwarding block'].
			self fwdBlockValidate: fwdBlock].
	self longAt: oop put: (self longAt: fwdBlock + 4)
]

{ #category : #become }
ObjectMemory >> restoreHeadersAfterBecoming: list1 with: list2 [ 
	"Restore the headers of all oops in both lists. Exchange their 
	hash bits so becoming objects in identity sets and 
	dictionaries doesn't change their hash value."
	| fieldOffset oop1 oop2 hdr1 hdr2 |
	fieldOffset _ self lastPointerOf: list1.
	[fieldOffset >= BaseHeaderSize]
		whileTrue: [oop1 _ self longAt: list1 + fieldOffset.
			oop2 _ self longAt: list2 + fieldOffset.
			self restoreHeaderOf: oop1.
			self restoreHeaderOf: oop2.
			"Exchange hash bits of the two objects."
			hdr1 _ self longAt: oop1.
			hdr2 _ self longAt: oop2.
			self longAt: oop1 put: ((hdr1 bitAnd: AllButHashBits) bitOr: (hdr2 bitAnd: HashBits)).
			self longAt: oop2 put: ((hdr2 bitAnd: AllButHashBits) bitOr: (hdr1 bitAnd: HashBits)).
			fieldOffset _ fieldOffset - 4]
]

{ #category : #become }
ObjectMemory >> restoreHeadersAfterForwardBecome: copyHashFlag [ 
	"Forward become leaves us with no original oops in the 
	mutated object list, 
	so we must enumerate the (four-word) forwarding blocks 
	where we have stored backpointers."
	"This loop start is copied from fwdBlockGet:"
	| oop1 fwdBlock oop2 hdr1 hdr2 |
	fwdBlock _ endOfMemory + BaseHeaderSize + 7 bitAnd: 4294967288.
	fwdBlock _ fwdBlock + 16.
	"fwdBlockGet: did a pre-increment"
	[fwdBlock <= fwdTableNext
	"fwdTableNext points to the last active block"]
		whileTrue: [oop1 _ self longAt: fwdBlock + 8.
			"Backpointer to mutated object."
			oop2 _ self longAt: fwdBlock.
			self restoreHeaderOf: oop1.
			copyHashFlag
				ifTrue: ["Change the hash of the new oop (oop2) to be that of the old (oop1) 
					so mutated objects in hash structures will be 
					happy after the change."
					hdr1 _ self longAt: oop1.
					hdr2 _ self longAt: oop2.
					self longAt: oop2 put: ((hdr2 bitAnd: AllButHashBits) bitOr: (hdr1 bitAnd: HashBits))].
			fwdBlock _ fwdBlock + 16]
]

{ #category : #'header access' }
ObjectMemory >> rightType: headerWord [
	"Compute the correct header type for an object based on the size and compact class fields of the given base header word, rather than its type bits. This is used during marking, when the header type bits are used to record the state of tracing."

	(headerWord bitAnd: SizeMask) = 0  "zero size field in header word"
		ifTrue: [ ^HeaderTypeSizeAndClass ]
		ifFalse: [ (headerWord bitAnd: CompactClassMask) = 0
				ifTrue: [ ^HeaderTypeClass ]
				ifFalse: [ ^HeaderTypeShort ]].
]

{ #category : #'header access' }
ObjectMemory >> setSizeOfFree: chunk to: byteSize [
	"Set the header of the given chunk to make it be a free chunk of the given size."

	self longAt: chunk put: ((byteSize bitAnd: AllButTypeMask) bitOr: HeaderTypeFree).
]

{ #category : #allocation }
ObjectMemory >> shrinkObjectMemory: delta [ 
	"Attempt to shrink the object memory by the given delta 
	amount "
	| limit |
	limit _ self sqShrinkMemory: memoryLimit By: delta.
	limit = memoryLimit
		ifFalse: [memoryLimit _ limit - 24.
			"remove a tad for safety"
			self initializeMemoryFirstFree: freeBlock]
]

{ #category : #'header access' }
ObjectMemory >> sizeBitsOf: oop [
	"Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words."
	"Note: byte indexable objects need to have low bits subtracted from this size."

	| header |
	header _ self baseHeader: oop.
	(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: AllButTypeMask ]
		ifFalse: [ ^ header bitAnd: SizeMask ].
]

{ #category : #'header access' }
ObjectMemory >> sizeBitsOfSafe: oop [
	"Compute the size of the given object from the cc and size fields in its header. This works even if its type bits are not correct."

	| header type |
	header _ self baseHeader: oop.
	type _ self rightType: header.
	type = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: AllButTypeMask ]
		ifFalse: [ ^ header bitAnd: SizeMask ].
]

{ #category : #'header access' }
ObjectMemory >> sizeHeader: oop [

	^ self longAt: oop - 8
]

{ #category : #'header access' }
ObjectMemory >> sizeOfFree: oop [
	"Return the size of the given chunk in bytes. Argument MUST be a free chunk."

	^ (self longAt: oop) bitAnd: AllButTypeMask
]

{ #category : #'interpreter access' }
ObjectMemory >> splObj: index [
	"Return one of the objects in the SpecialObjectsArray"
	^ self fetchPointer: index ofObject: specialObjectsOop
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> startField [
	"Examine and possibly trace the next field of the object being 
	traced. See comment in markAndTrace for explanation of 
	tracer state variables."
	| typeBits childType |
	self inline: true.
	child _ self longAt: field.
	typeBits _ child bitAnd: TypeMask.
	(typeBits bitAnd: 1) = 1
		ifTrue: ["field contains a SmallInteger; skip it"
			field _ field - 4.
			^ StartField].
	typeBits = 0 ifTrue: ["normal oop, go down"
			self longAt: field put: parentField.
			parentField _ field.
			^ StartObj].
	typeBits = 2 ifTrue: ["reached the header; do we need to process the class word? "
			(child bitAnd: CompactClassMask) ~= 0
				ifTrue: ["object's class is compact; we're done"
					"restore the header type bits"
					child _ child bitAnd: AllButTypeMask.
					childType _ self rightType: child.
					self longAt: field put: (child bitOr: childType).
					^ Upward]
				ifFalse: ["object has a full class word; process that class"
					child _ self longAt: field - 4. "class word"
					child _ child bitAnd: AllButTypeMask. "clear type bits"
					self longAt: field - 4 put: parentField.
					parentField _ field - 4 bitOr: 1.
					"point at class word; mark as working on the class. "
					^ StartObj]]
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> startObj [
	"Start tracing the object 'child' and answer the next action. 
	The object may be anywhere in the middle of being swept 
	itself. See comment in markAndTrace for explanation of 
	tracer state variables."
	| oop header lastFieldOffset |
	self inline: true.
	oop _ child.
	oop < youngStartLocal
		ifTrue: ["old object; skip it"
			field _ oop.
			^ Upward].
	header _ self longAt: oop.
	(header bitAnd: MarkBit) = 0
		ifTrue: ["unmarked; mark and trace"
			"Do not trace the object's indexed fields if it's a weak class "
			(self isWeakNonInt: oop)
				ifTrue: ["Set lastFieldOffset before the weak fields in the receiver "
					lastFieldOffset _ (self nonWeakFieldsOf: oop) << 2]
				ifFalse: ["Do it the usual way"
					lastFieldOffset _ self lastPointerOf: oop].
			header _ header bitAnd: AllButTypeMask.
			header _ (header bitOr: MarkBit) bitOr: HeaderTypeGC.
			self longAt: oop put: header.
			field _ oop + lastFieldOffset.
			^ StartField "trace its fields and class"]
		ifFalse: ["already marked; skip it"
			field _ oop.
			^ Upward]
]

{ #category : #'object enumeration' }
ObjectMemory >> startOfMemory [
	"Return the start of object memory."

	^ self cCode: '(int) memory'
]

{ #category : #'interpreter access' }
ObjectMemory >> storeByte: byteIndex ofObject: oop withValue: valueByte [

	^ self byteAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + byteIndex put: valueByte
]

{ #category : #'interpreter access' }
ObjectMemory >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [ 
	"Note must check here for stores of young objects into old ones. "

	oop < youngStart ifTrue: [self possibleRootStoreInto: oop value: valuePointer].
	^ self longAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + (fieldIndex << 2) put: valuePointer
]

{ #category : #'interpreter access' }
ObjectMemory >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	"Like storePointer:ofObject:withValue:, but the caller guarantees that the object being stored into is a young object or is already marked as a root."

	^ self longAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + (fieldIndex << 2) put: valuePointer

]

{ #category : #'interpreter access' }
ObjectMemory >> storeWord: fieldIndex ofObject: oop withValue: valueWord [

	^ self longAt: (self cCoerce: oop to: 'char *') + BaseHeaderSize + (fieldIndex << 2) put: valueWord
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceAfterGC: minFree [ 
	"Return true if there is enough free space after doing a garbage collection. If not, signal that space is low."
	| growSize |
	self inline: false.

	self incrementalGC. "try to recover some space"

	(self cCoerce: (self sizeOfFree: freeBlock) to: 'unsigned ') < (self cCoerce: minFree to: 'unsigned ')
		ifTrue: [signalLowSpace ifTrue: [^false]. "give up; problem is already noted"
			self fullGC. "try harder"
			"for stability, require more free space after doing an expensive full GC"
			(self cCoerce: (self sizeOfFree: freeBlock) to: 'unsigned ') >= ((self cCoerce: minFree to: 'unsigned ') + 15000) ifTrue: [^ true].

			"still not enough; attempt to grow object memory"
			growSize _ minFree - (self sizeOfFree: freeBlock) + growHeadroom.
			self growObjectMemory: growSize.

			(self cCoerce: (self sizeOfFree: freeBlock) to: 'unsigned ') >= ((self cCoerce: minFree to: 'unsigned ') + 15000) ifTrue: [^true].

			"still not enough"
			^false].
	^true
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceToAllocate: bytes [
	"Return true if there is enough space to allocate the given number of bytes, perhaps after doing a garbage collection."

	| minFree |
	self inline: true.
	minFree _ lowSpaceThreshold + bytes + BaseHeaderSize.

	"check for low-space"
	(self cCoerce: (self sizeOfFree: freeBlock) to: 'unsigned ') >= (self cCoerce: minFree to: 'unsigned ')
		ifTrue: [^true]
		ifFalse: [^self sufficientSpaceAfterGC: minFree].
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> sweepPhase [
	"Sweep memory from youngStart through the end of memory. Free all 
	inaccessible objects and coalesce adjacent free chunks. Clear the mark 
	bits of accessible objects. Compute the starting point for the first pass of 
	incremental compaction (compStart). Return the number of surviving 
	objects. "
	"Details: Each time a non-free object is encountered, decrement the 
	number of available forward table entries. If all entries are spoken for 
	(i.e., entriesAvailable reaches zero), set compStart to the last free 
	chunk before that object or, if there is no free chunk before the given 
	object, the first free chunk after it. Thus, at the end of the sweep 
	phase, compStart through compEnd spans the highest collection of 
	non-free objects that can be accomodated by the forwarding table. This 
	information is used by the first pass of incremental compaction to 
	ensure that space is initially freed at the end of memory. Note that 
	there should always be at least one free chunk--the one at the end of 
	the heap."
	| entriesAvailable survivors freeChunk firstFree oop oopHeader oopHeaderType hdrBytes oopSize freeChunkSize endOfMemoryLocal |
	self inline: false.
	entriesAvailable _ self fwdTableInit: 8.
	survivors _ 0.
	freeChunk _ nil.
	firstFree _ nil.
	"will be updated later"
	endOfMemoryLocal _ endOfMemory.
	oop _ self oopFromChunk: youngStart.
	[oop < endOfMemoryLocal]
		whileTrue: ["get oop's header, header type, size, and header size"
			oopHeader _ self baseHeader: oop.
			oopHeaderType _ oopHeader bitAnd: TypeMask.
			hdrBytes _ headerTypeBytes at: oopHeaderType.
			(oopHeaderType bitAnd: 1) = 1
				ifTrue: [oopSize _ oopHeader bitAnd: SizeMask]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize _ (self sizeHeader: oop) bitAnd: AllButTypeMask]
						ifFalse: ["free chunk" oopSize _ oopHeader bitAnd: AllButTypeMask]].
			(oopHeader bitAnd: MarkBit) = 0
				ifTrue: ["object is not marked; free it"
					"<-- Finalization support: We need to mark each oop chunk as free -->"
					self longAt: oop - hdrBytes put: HeaderTypeFree.
					freeChunk ~= nil
						ifTrue: ["enlarge current free chunk to include this oop"
							freeChunkSize _ freeChunkSize + oopSize + hdrBytes]
						ifFalse: ["start a new free chunk"
							freeChunk _ oop - hdrBytes.
							"chunk may start 4 or 8 bytes before oop"
							freeChunkSize _ oopSize + (oop - freeChunk).
							"adjust size for possible extra header bytes"
							firstFree = nil ifTrue: [firstFree _ freeChunk]]]
				ifFalse: ["object is marked; clear its mark bit and possibly adjust 
					the compaction start"
					self longAt: oop put: (oopHeader bitAnd: AllButMarkBit).
					"<-- Finalization support: Check if we're running about a weak class -->"
					(self isWeakNonInt: oop) ifTrue: [self finalizeReference: oop].
					entriesAvailable > 0
						ifTrue: [entriesAvailable _ entriesAvailable - 1]
						ifFalse: ["start compaction at the last free chunk before this object"
							firstFree _ freeChunk].
					freeChunk ~= nil
						ifTrue: ["record the size of the last free chunk"
							self longAt: freeChunk put: ((freeChunkSize bitAnd: AllButTypeMask) bitOr: HeaderTypeFree).
							freeChunk _ nil].
					survivors _ survivors + 1].
			oop _ self oopFromChunk: oop + oopSize].
	freeChunk ~= nil
		ifTrue: ["record size of final free chunk"
			self longAt: freeChunk put: ((freeChunkSize bitAnd: AllButTypeMask) bitOr: HeaderTypeFree)].
	oop = endOfMemory
		ifFalse: [self error: 'sweep failed to find exact end of memory'].
	firstFree = nil
		ifTrue: [self error: 'expected to find at least one free object']
		ifFalse: [compStart _ firstFree].

	^ survivors
]

{ #category : #'plugin support' }
ObjectMemory >> trueObject [
	^trueObj
]

{ #category : #'gc -- compaction' }
ObjectMemory >> updatePointersInRangeFrom: memStart to: memEnd [ 
	"update pointers in the given memory range"
	| oop |
	self inline: false.
	oop _ self oopFromChunk: memStart.
	[oop < memEnd]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [self remapFieldsAndClassOf: oop].
			oop _ self objectAfterWhileForwarding: oop]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> updatePointersInRootObjectsFrom: memStart to: memEnd [ 
	"update pointers in root objects"
	| oop |
	self inline: false.
	1 to: rootTableCount do: [:i | 
			oop _ rootTable at: i.
			(oop < memStart or: [oop >= memEnd])
				ifTrue: ["Note: must not remap the fields of any object twice!"
					"remap this oop only if not in the memory range 
					covered below"
					self remapFieldsAndClassOf: oop]]
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> upward [
	"Return from marking an object below. Incoming: 
	field = oop we just worked on, needs to be put away 
	parentField = where to put it in our object 
	NOTE: Type field of object below has already been restored!!! "
	| type header |
	self inline: true.
	(parentField bitAnd: 1) = 1
		ifTrue: [parentField = GCTopMarker
				ifTrue: ["top of the chain"
					header _ (self longAt: field) bitAnd: AllButTypeMask.
					type _ self rightType: header.
					self longAt: field put: (header bitOr: type). "install type on class oop"
					^ Done]
				ifFalse: ["was working on the extended class word"
					child _ field. "oop of class"
					field _ parentField - 1. "class word, ** clear the low bit **"
					parentField _ self longAt: field.
					header _ self longAt: field + 4. "base header word"
					type _ self rightType: header.
					self longAt: field put: (child bitOr: type). "install type on class oop"
					field _ field + 4. "point at header"
					"restore type bits"
					header _ header bitAnd: AllButTypeMask.
					self longAt: field put: (header bitOr: type).
					^ Upward]]
		ifFalse: ["normal"
			child _ field. "who we worked on below"
			field _ parentField. "where to put it"
			parentField _ self longAt: field.
			self longAt: field put: child.
			field _ field - 4. "point at header"
			^ StartField]
]

{ #category : #'memory access' }
ObjectMemory >> validateRoots [ 
	"Verify that every old object that points to a new object 
		has its root bit set, and
		appears in the rootTable.
	This method should not be called if the rootTable is full, because roots
	are no longer recorded, and incremental collections are not attempted.
	If DoAssertionChecks is true, this routine will halt on an unmarked root.
	Otherwise, this routine will merely return true in that case."
	| oop fieldAddr fieldOop header badRoot |
	badRoot _ false.
	oop _ self firstObject.

	[oop < youngStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[fieldAddr _ oop + (self lastPointerOf: oop).
			[fieldAddr > oop] whileTrue:
				[fieldOop _ self longAt: fieldAddr.
				(fieldOop >= youngStart and: [(self isIntegerObject: fieldOop) not]) ifTrue:
					["fieldOop is a pointer to a young object"
					header _ self longAt: oop.
					(header bitAnd: RootBit) = 0
					ifTrue:
						["Forbidden: points to young obj but root bit not set."
						DoAssertionChecks ifTrue: [self error: 'root bit not set'].
						badRoot _ true]
					ifFalse:
						["Root bit is set"
						"Extreme test -- validate that oop was entered in rootTable too..."
						"Disabled for now...
						found _ false.
						1 to: rootTableCount do:
							[:i | oop = (rootTable at: i) ifTrue: [found _ true]].
						found ifFalse:
							[DoAssertionChecks ifTrue: [self error: 'root table not set'].
							badRoot _ true].
						..."
						]].
				fieldAddr _ fieldAddr - 4]].
		oop _ self objectAfter: oop].
	^ badRoot
]
