"
This class describes a 32-bit direct-pointer object memory for Smalltalk.  The model is very simple in principle:  a pointer is either a SmallInteger or a 32-bit direct object pointer.

SmallIntegers are tagged with a low-order bit equal to 1, and an immediate 31-bit 2s-complement signed value in the rest of the word.

All object pointers point to a header, which may be followed by a number of data fields.  This object memory achieves considerable compactness by using a variable header size (the one complexity of the design).  The format of the 0th header word is as follows:

	3 bits	reserved for gc (mark, root, unused)
	12 bits	object hash (for HashSets)
	5 bits	compact class index
	4 bits	object format
	6 bits	object size in 32-bit words
	2 bits	header type (0: 3-word, 1: 2-word, 2: forbidden, 3: 1-word)

If a class is in the compact class table, then this is the only header information needed.  If it is not, then it will have another header word at offset -4 bytes with its class in the high 30 bits, and the header type repeated in its low 2 bits.  It the objects size is greater than 255 bytes, then it will have yet another header word at offset -8 bytes with its full word size in the high 30 bits and its header type repeated in the low two bits.

The object format field provides the remaining information as given in the formatOf: method (including isPointers, isVariable, isBytes, and the low 2 size bits of byte-sized objects).

This implementation includes incremental (2-generation) and full garbage collection, each with compaction and rectification of direct pointers.  It also supports a bulk-become (exchange object identity) feature that allows many objects to be becomed at once, as when all instances of a class must be grown or shrunk.

There is now a simple 64-bit version of the object memory.  It is the simplest possible change that could work.  It merely sign-extends all integer oops, and extends all object headers and oops by adding 32 zeroes in the high bits.  The format of the base header word is changed in one minor, not especially elegant, way.  Consider the old 32-bit header:
	ggghhhhhhhhhhhhcccccffffsssssstt
The 64-bit header is almost identical, except that the size field (now being in units of 8 bytes, has a zero in its low-order bit.  At the same time, the byte-size residue bits for byte objects, which are in the low order bits of formats 8-11 and 12-15, are now in need of another bit of residue.  So, the change is as follows:
	ggghhhhhhhhhhhhcccccffffsssssrtt
where bit r supplies the 4's bit of the byte size residue for byte objects.  Oh, yes, this is also needed now for 'variableWord' objects, since their size in 32-bit words requires a low-order bit.

See the comment in formatOf: for the change allowing for 64-bit wide bitmaps, now dubbed 'variableLong'.
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
		'extraRoots',
		'extraRootCount',
		'weakRoots',
		'weakRootCount',
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
		'gcSemaphoreIndex',
		'gcBiasToGrow',
		'gcBiasToGrowGCLimit',
		'gcBiasToGrowThreshold',
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
		'youngStartLocal',
		'statMarkCount',
		'statSweepCount',
		'statMkFwdCount',
		'statCompMoveCount',
		'statGrowMemory',
		'statShrinkMemory',
		'statRootTableCount',
		'statAllocationCount',
		'statSurvivorCount',
		'statGCTime',
		'statSpecialMarkCount',
		'statIGCDeltaTime',
		'statpendingFinalizationSignals',
		'forceTenureFlag'
	],
	#classVars : [
		'BlockContextProto',
		'Byte0Mask',
		'Byte0Shift',
		'Byte1Mask',
		'Byte1Shift',
		'Byte1ShiftNegated',
		'Byte2Mask',
		'Byte2Shift',
		'Byte3Mask',
		'Byte3Shift',
		'Byte3ShiftNegated',
		'Byte4Mask',
		'Byte4Shift',
		'Byte4ShiftNegated',
		'Byte5Mask',
		'Byte5Shift',
		'Byte5ShiftNegated',
		'Byte6Mask',
		'Byte6Shift',
		'Byte7Mask',
		'Byte7Shift',
		'Byte7ShiftNegated',
		'Bytes3to0Mask',
		'Bytes7to4Mask',
		'CharacterTable',
		'ClassAlien',
		'ClassArray',
		'ClassBitmap',
		'ClassBlockClosure',
		'ClassBlockContext',
		'ClassByteArray',
		'ClassCharacter',
		'ClassCompiledMethod',
		'ClassExternalAddress',
		'ClassExternalData',
		'ClassExternalFunction',
		'ClassExternalLibrary',
		'ClassExternalStructure',
		'ClassFloat',
		'ClassInteger',
		'ClassLargeNegativeInteger',
		'ClassLargePositiveInteger',
		'ClassMessage',
		'ClassMethodContext',
		'ClassPoint',
		'ClassProcess',
		'ClassPseudoContext',
		'ClassSemaphore',
		'ClassString',
		'ClassTranslatedMethod',
		'ClassUnsafeAlien',
		'ClassWeakFinalizer',
		'CompactClassMask',
		'CompactClasses',
		'ConstMinusOne',
		'ConstOne',
		'ConstTwo',
		'ConstZero',
		'ContextFixedSizePlusHeader',
		'CtxtTempFrameStart',
		'DoAssertionChecks',
		'DoBalanceChecks',
		'Done',
		'ExternalObjectsArray',
		'ExtraRootSize',
		'FalseObject',
		'GCTopMarker',
		'HashBits',
		'HashBitsOffset',
		'HeaderTypeClass',
		'HeaderTypeFree',
		'HeaderTypeGC',
		'HeaderTypeShort',
		'HeaderTypeSizeAndClass',
		'InvokeCallbackSelector',
		'LargeContextBit',
		'MethodContextProto',
		'NilContext',
		'NilObject',
		'ProcessSignalingLowSpace',
		'RemapBufferSize',
		'RootTableRedZone',
		'RootTableSize',
		'SchedulerAssociation',
		'SelectorAboutToReturn',
		'SelectorAttemptToAssign',
		'SelectorCannotInterpret',
		'SelectorCannotReturn',
		'SelectorDoesNotUnderstand',
		'SelectorMustBeBoolean',
		'SelectorRunWithIn',
		'SpecialSelectors',
		'StackStart',
		'StartField',
		'StartObj',
		'TheDisplay',
		'TheFinalizationSemaphore',
		'TheInputSemaphore',
		'TheInterruptSemaphore',
		'TheLowSpaceSemaphore',
		'TheTimerSemaphore',
		'TrueObject',
		'TypeMask',
		'Upward'
	],
	#classInstVars : [
		'timeStamp'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #accessing }
ObjectMemory class >> byte0Mask [
	^Byte0Mask
]

{ #category : #accessing }
ObjectMemory class >> byte0Shift [
	^Byte0Shift
]

{ #category : #accessing }
ObjectMemory class >> byte1Mask [
	^Byte1Mask
]

{ #category : #accessing }
ObjectMemory class >> byte1Shift [
	^Byte1Shift
]

{ #category : #accessing }
ObjectMemory class >> byte1ShiftNegated [
	^Byte1ShiftNegated
]

{ #category : #accessing }
ObjectMemory class >> byte2Mask [
	^Byte2Mask
]

{ #category : #accessing }
ObjectMemory class >> byte2Shift [
	^Byte2Shift
]

{ #category : #accessing }
ObjectMemory class >> byte3Mask [
	^Byte3Mask
]

{ #category : #accessing }
ObjectMemory class >> byte3Shift [
	^Byte3Shift
]

{ #category : #accessing }
ObjectMemory class >> byte3ShiftNegated [
	^Byte3ShiftNegated
]

{ #category : #accessing }
ObjectMemory class >> byte4Mask [
	^Byte4Mask
]

{ #category : #accessing }
ObjectMemory class >> byte4Shift [
	^Byte4Shift
]

{ #category : #accessing }
ObjectMemory class >> byte4ShiftNegated [
	^Byte4ShiftNegated
]

{ #category : #accessing }
ObjectMemory class >> byte5Mask [
	^Byte5Mask
]

{ #category : #accessing }
ObjectMemory class >> byte5Shift [
	^Byte5Shift
]

{ #category : #accessing }
ObjectMemory class >> byte5ShiftNegated [
	^Byte5ShiftNegated
]

{ #category : #accessing }
ObjectMemory class >> byte6Mask [
	^Byte6Mask
]

{ #category : #accessing }
ObjectMemory class >> byte6Shift [
	^Byte6Shift
]

{ #category : #accessing }
ObjectMemory class >> byte7Mask [
	^Byte7Mask
]

{ #category : #accessing }
ObjectMemory class >> byte7Shift [
	^Byte7Shift
]

{ #category : #accessing }
ObjectMemory class >> byte7ShiftNegated [
	^Byte7ShiftNegated
]

{ #category : #accessing }
ObjectMemory class >> bytes3to0Mask [
	^Bytes3to0Mask
]

{ #category : #accessing }
ObjectMemory class >> bytes7to4Mask [
	^Bytes7to4Mask
]

{ #category : #translation }
ObjectMemory class >> declareCAsOop: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: 'usqInt']
]

{ #category : #translation }
ObjectMemory class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: #memory type:#'usqInt'.
	aCCodeGenerator
		var: #remapBuffer
		declareC: 'sqInt remapBuffer[', (RemapBufferSize + 1) printString, ']'.
	aCCodeGenerator
		var: #rootTable
		declareC: 'sqInt rootTable[', (RootTableSize + 1) printString, ']'.
	"Weak roots must be large enough for roots+remapBuffer+sizeof(allCallsOn: #markAndTrace:)"
	aCCodeGenerator
		var: #weakRoots
		declareC: 'sqInt weakRoots[', (RootTableSize + RemapBufferSize + 100) printString, ']'.
	aCCodeGenerator
		var: #extraRoots
		declareC: 'sqInt* extraRoots[', (ExtraRootSize + 1) printString, ']'.
	aCCodeGenerator
		var: #headerTypeBytes
		declareC: 'sqInt headerTypeBytes[4]'.
	
	self declareCAsOop: {
			#youngStart .
			#endOfMemory .
			#memoryLimit .
			#youngStartLocal .
			#freeBlock .
			#compStart .
			#compEnd .
			#fwdTableNext .
			#fwdTableLast .
			#gcBiasToGrowThreshold .
			#shrinkThreshold .
			#growHeadroom }
		in: aCCodeGenerator

]

{ #category : #initialization }
ObjectMemory class >> initializeConstants [
	"ObjectMemory initializeConstants"

	self initializeObjectWordConstants.

	"Translation flags (booleans that control code generation via conditional translation):"
	DoAssertionChecks := false.  "generate assertion checks"
	DoBalanceChecks := false. "generate stack balance checks"

	self initializeSpecialObjectIndices.
	self initializeObjectHeaderConstants.

	CtxtTempFrameStart := 6.  "Copy of TempFrameStart in Interp"
	ContextFixedSizePlusHeader := CtxtTempFrameStart + 1.
	
	LargeContextBit := 16r40000.  "This bit set in method headers if large context is needed."
	NilContext := 1.  "the oop for the integer 0; used to mark the end of context lists"

	RemapBufferSize := 25.
	RootTableSize := 2500.  	"number of root table entries (4 bytes/entry)"
	RootTableRedZone := RootTableSize - 100.	"red zone of root table - when reached we force IGC"

	"tracer actions"
	StartField := 1.
	StartObj := 2.
	Upward := 3.
	Done := 4.

	ExtraRootSize := 2048. "max. # of external roots"
]

{ #category : #initialization }
ObjectMemory class >> initializeObjectHeaderConstants [

	"masks for type field"
	TypeMask := 3.

	"type field values"
	HeaderTypeSizeAndClass := 0.
	HeaderTypeClass := 1.
	HeaderTypeFree := 2.
	HeaderTypeShort := 3.

	"type field values used during the mark phase of GC"
	HeaderTypeGC := 2.
	GCTopMarker := 3.  "neither an oop, nor an oop+1, this value signals that we have crawled back up to the top of the marking phase."

	"Base header word bit fields"
	HashBits := 16r1FFE0000.
	HashBitsOffset := 17.

	CompactClassMask := 16r1F000

]

{ #category : #initialization }
ObjectMemory class >> initializeObjectWordConstants [

	Byte0Shift := 0.
	Byte1Shift := 8.
	Byte2Shift := 16.
	Byte3Shift := 24.
	Byte4Shift := 32.
	Byte5Shift := 40.
	Byte6Shift := 48.
	Byte7Shift := 56.

	Byte0Mask := 16r00000000000000FF.
	Byte1Mask := 16r000000000000FF00.
	Byte2Mask := 16r0000000000FF0000.
	Byte3Mask := 16r00000000FF000000.
	Byte4Mask := 16r000000FF00000000.
	Byte5Mask := 16r0000FF0000000000.
	Byte6Mask := 16r00FF000000000000.
	Byte7Mask := 16rFF00000000000000.
	Bytes3to0Mask := 16r00000000FFFFFFFF.
	Bytes7to4Mask := 16rFFFFFFFF00000000.
							
	Byte1ShiftNegated := Byte1Shift negated.
	Byte3ShiftNegated := Byte3Shift negated.
	Byte4ShiftNegated := Byte4Shift negated.
	Byte5ShiftNegated := Byte5Shift negated.
	Byte7ShiftNegated := Byte7Shift negated
]

{ #category : #initialization }
ObjectMemory class >> initializeSpecialObjectIndices [
	"Initialize indices into specialObjects array."

	NilObject := 0.
	FalseObject := 1.
	TrueObject := 2.
	SchedulerAssociation := 3.
	ClassBitmap := 4.
	ClassInteger := 5.
	ClassString := 6.
	ClassArray := 7.
	"SmalltalkDictionary := 8."  "Do not delete!"
	ClassFloat := 9.
	ClassMethodContext := 10.
	ClassBlockContext := 11.
	ClassPoint := 12.
	ClassLargePositiveInteger := 13.
	TheDisplay := 14.
	ClassMessage := 15.
	ClassCompiledMethod := 16.
	TheLowSpaceSemaphore := 17.
	ClassSemaphore := 18.
	ClassCharacter := 19.
	SelectorDoesNotUnderstand := 20.
	SelectorCannotReturn := 21.
	ProcessSignalingLowSpace := 22.	"was TheInputSemaphore"
	SpecialSelectors := 23.
	CharacterTable := 24.
	SelectorMustBeBoolean := 25.
	ClassByteArray := 26.
	ClassProcess := 27.
	CompactClasses := 28.
	TheTimerSemaphore := 29.
	TheInterruptSemaphore := 30.
	SelectorCannotInterpret := 34.
	"Was MethodContextProto := 35."
	ClassBlockClosure := 36.
	"Was BlockContextProto := 37."
	ExternalObjectsArray := 38.
	ClassPseudoContext := 39.
	ClassTranslatedMethod := 40.
	TheFinalizationSemaphore := 41.
	ClassLargeNegativeInteger := 42.

	ClassExternalAddress := 43.
	ClassExternalStructure := 44.
	ClassExternalData := 45.
	ClassExternalFunction := 46.
	ClassExternalLibrary := 47.

	SelectorAboutToReturn := 48.
	SelectorRunWithIn := 49.
	SelectorAttemptToAssign := 50.

	"PrimErrTableIndex := 51. in Interpreter class>>initializePrimitiveErrorCodes"

	ClassAlien := 52.
	InvokeCallbackSelector := 53.
	ClassUnsafeAlien := 54.

	ClassWeakFinalizer := 55

]

{ #category : #translation }
ObjectMemory class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
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

{ #category : #translation }
ObjectMemory class >> unsignedIntegerSuffix [
	"Answer the suffix that should be appended to unsigned integer literals in generated code."

	^ 'U'

	"The U declaration is sufficient for 64-bit cases - dtl"
	"^BytesPerWord = 4 ifTrue: ['U'] ifFalse: ['ULL']"
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> aComment [
	"The mark phase is based on a pointer reversing traversal. This is a little tricky because the class, which is needed by the traversal, may be in either the header (as a compact class index) or in the word above the header. See memo 'Revised object format'.
	Compact classes are marked and traced separately.
	How do you know that you are returning from having marked a class? Parent pointer has 10 in low bits.

Here are the states an object may be in, followed by what to do next in brackets []:

  Start Object: parentField is set, [obj := child]:
	obj is pointed at by a field in parent that is being traced now. obj is marked.
		[(parent goes up to the next field) field addr := obj. go to Upward]
	obj is pointed at by a field in parent that is being traced now. obj is unmarked. obj has no pointers.
		[put 10 into low bits of header. field addr := obj. go to Start Field (to process class word)]
	obj is pointed at by a field in parent that is being traced now. obj is unmarked. obj has pointers.
		[put 10 into low bits of header. point to last field. go to Start Field]

  Start Field: 
	Field ends in 10. It is the header. Short Class is not 0.
		[Set low bits to correct value. (have parent pointer) go to Upward]
	Field ends in 10. It is the header. Short Class is 0.
		[child := word above header. low bits of child := 01. class word := parentField. parentField := loc of class word. go to Start Obj]
	Field is Integer.
		[point one word up, go to Start Field]
	Field is oop.
		[child := field. field := parentField. parentField := loc of field. go to Start Obj]

  Upward [restore low bits of header (at field addr)]:
	parentField is 3. (bits 11, int 1).
		[done!]
	parentField ends in 00.
		[child := field addr. field addr := parentField. parentField := field addr contents.
		field addr contents := child (addr of prev object. its oop). field addr - 4. go to Start Field]
	parentField ends in 01. We're tracing the class.
		[child := field addr. field addr := parentField (loc of class word). parentField := field addr contents.
		field addr contents := child (addr of prev object. its oop). field addr + 4 (header). go to Upward]
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
		o1 := Object new.
		w1 := WeakReference on: o1.
		o2 := Object new.
		w2 := WeakReference on: o2.
		o1 become: o2.
The become: operation makes w1 point to o2 and because o2 has been created AFTER w1 the object reference in w1 points forward. Why might this be a problem? Well, if the GC would start after the weak reference AND free the object then the weak reference would simply point to an invalid memory location (since we've not been checking the weak reference during sweep phase).

	Fortunately, this can not happen in the current ObjectMemory implementation. Why? Well, the only GC not starting at the beginning of the memory is incremental GC. Incremental GC however is only executed in so-called youngSpace. If both, the weak reference AND the object it points to reside in youngSpace then we can still check the weak reference. If however, the weak reference is not in youngSpace but the object is, then the reference is itself a root for young space and will be processed by the GC.

	In the end, we just need a little adjustment in step 2b) of the above procedure which looks as follows:
		If the weak reference points 
			* backwards: check if the object header is marked free
			* forwards: check if the object has been marked in markPhase.

	Note that a number of finalizations will only be executed during a fullGC. So, if you must garantuee that some object has been finalized you definitely need to do a fullGC.

ar 3/20/98 17:20"

	self error:'Comment only'.
]

{ #category : #'object enumeration' }
ObjectMemory >> accessibleObjectAfter: oop [ 
	"Return the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted."
	| obj |
	<inline: false>
	obj := self objectAfter: oop.
	[self oop: obj isLessThan: endOfMemory]
		whileTrue: [(self isFreeObject: obj) ifFalse: [^ obj].
			obj := self objectAfter: obj].
	^ nil
]

{ #category : #'plugin support' }
ObjectMemory >> addGCRoot: varLoc [
	"Add the given variable location to the extra roots table"
	<export: true>
	<var: #varLoc declareC: 'sqInt *varLoc'>
	extraRootCount >= ExtraRootSize ifTrue:[^false]. "out of space"
	extraRoots at: (extraRootCount := extraRootCount+1) put: varLoc.
	^true
]

{ #category : #initialization }
ObjectMemory >> adjustAllOopsBy: bytesToShift [ 
	"Adjust all oop references by the given number of bytes. This 
	is done just after reading in an image when the new base 
	address of the object heap is different from the base address 
	in the image."
	"di 11/18/2000 - return number of objects found"

	| oop totalObjects |
	<inline: false>
	bytesToShift = 0 ifTrue: [^300000].
	"this is probably an improvement over the previous answer of 
	nil, but maybe we should do the obejct counting loop and 
	simply guard the adjustFieldsAndClass... with a bytesToShift 
	= 0 ifFalse: ?"
	totalObjects := 0.
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory]
		whileTrue:
			[(self isFreeObject: oop)
				ifFalse:
					[totalObjects := totalObjects + 1.
					 self adjustFieldsAndClassOf: oop by: bytesToShift].
			 oop := self objectAfter: oop].
	^totalObjects
]

{ #category : #initialization }
ObjectMemory >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
	"Adjust all pointers in this object by the given offset."
	| fieldAddr fieldOop classHeader newClassOop |
	<inline: true>
	offsetBytes = 0 ifTrue: [^nil].
	fieldAddr := oop + (self lastPointerOf: oop).
	[self oop: fieldAddr isGreaterThan: oop]
		whileTrue: [fieldOop := self longAt: fieldAddr.
			(self isIntegerObject: fieldOop)
				ifFalse: [self longAt: fieldAddr put: fieldOop + offsetBytes].
			fieldAddr := fieldAddr - self bytesPerWord].
	(self headerType: oop) ~= HeaderTypeShort
		ifTrue: ["adjust class header if not a compact class"
			classHeader := self longAt: oop - self bytesPerWord.
			newClassOop := (classHeader bitAnd: self allButTypeMask) + offsetBytes.
			self longAt: oop - self bytesPerWord put: (newClassOop bitOr: (classHeader bitAnd: TypeMask))]
]

{ #category : #constants }
ObjectMemory >> allButHashBits [
	"Base header word bit fields"

	<inline: true>
	^self
		cCode: 'ALL_BUT_HASH_BITS'
		inSmalltalk: [self wordMask - HashBits]

]

{ #category : #constants }
ObjectMemory >> allButMarkBit [
	"Mask for mark bit"

	<inline: true>
	^self
		cCode: 'ALL_BUT_MARK_BIT'
		inSmalltalk: [self wordMask - self markBit]

]

{ #category : #constants }
ObjectMemory >> allButMarkBitAndTypeMask [

	<inline: true>
	^self
		cCode: 'ALL_BUT_MARK_BIT_AND_TYPE_MASK'
		inSmalltalk: [self allButTypeMask - self markBit]

]

{ #category : #constants }
ObjectMemory >> allButRootBit [
	"Mask for root bit"

	<inline: true>
	^self
		cCode: 'ALL_BUT_ROOT_BIT'
		inSmalltalk: [self wordMask - self rootBit]

]

{ #category : #constants }
ObjectMemory >> allButTypeMask [
	"Mask for type field"

	<inline: true>
	^self
		cCode: 'ALL_BUT_TYPE_MASK'
		inSmalltalk: [self wordMask - TypeMask]

]

{ #category : #become }
ObjectMemory >> allYoung: array1 and: array2 [ 
	"Return true if all the oops in both arrays, and the arrays 
	themselves, are in the young object space."
	| fieldOffset |
	(self oop: array1 isLessThan: youngStart)
		ifTrue: [^ false].
	(self oop: array2 isLessThan: youngStart)
		ifTrue: [^ false].
	fieldOffset := self lastPointerOf: array1.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[(self oop: (self longAt: array1 + fieldOffset) isLessThan: youngStart)
			ifTrue: [^ false].
		(self oop: (self longAt: array2 + fieldOffset) isLessThan: youngStart)
			ifTrue: [^ false].
		fieldOffset := fieldOffset - self bytesPerWord].
	^ true
]

{ #category : #allocation }
ObjectMemory >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill with: fillWord [ 
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes space for the base header word.) Initialize the header fields of the new object and fill the remainder of the object with the given value.
	May cause a GC"

	| newObj remappedClassOop end i |
	<inline: true>
	<var: #i type: 'usqInt'>
	<var: #end type: 'usqInt'>
	"remap classOop in case GC happens during allocation"
	hdrSize > 1 ifTrue: [self pushRemappableOop: classOop].
	newObj := self allocateChunk: byteSize + (hdrSize - 1 * self bytesPerWord).
	hdrSize > 1 ifTrue: [remappedClassOop := self popRemappableOop].

	hdrSize = 3
		ifTrue: [self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + self bytesPerWord put: (remappedClassOop bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + (self bytesPerWord*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
			newObj := newObj + (self bytesPerWord*2)].

	hdrSize = 2
		ifTrue: [self longAt: newObj put: (remappedClassOop bitOr: HeaderTypeClass).
			self longAt: newObj + self bytesPerWord put: (baseHeader bitOr: HeaderTypeClass).
			newObj := newObj + self bytesPerWord].

	hdrSize = 1
		ifTrue: [self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].
	"clear new object"
	doFill ifTrue: [end := newObj + byteSize.
			i := newObj + self bytesPerWord.
			[i < end] whileTrue: [self longAt: i put: fillWord.
					i := i + self bytesPerWord]].
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
	<inline: true>

	allocationCount >= allocationsBetweenGCs
		ifTrue: ["do an incremental GC every so many allocations to  keep pauses short"
			self incrementalGC].

	enoughSpace := self sufficientSpaceToAllocate: byteSize.
	enoughSpace
		ifFalse: ["signal that space is running low, but proceed with allocation if possible"
			signalLowSpace := true.
			lowSpaceThreshold := 0. "disable additional interrupts until lowSpaceThreshold is reset by image"
			self saveProcessSignalingLowSpace.
			self forceInterruptCheck].
	(self oop: (self sizeOfFree: freeBlock) isLessThan: byteSize + self baseHeaderSize)
		ifTrue: [self error: 'out of memory'].

	"if we get here, there is enough space for allocation to  succeed "
	newFreeSize := (self sizeOfFree: freeBlock) - byteSize.
	newChunk := freeBlock.
	freeBlock := freeBlock + byteSize.

	"Assume: client will initialize object header of free chunk, so following is not needed:"
	"self setSizeOfFree: newChunk to: byteSize."
	self setSizeOfFree: freeBlock to: newFreeSize.
	allocationCount := allocationCount + 1.
	^newChunk
]

{ #category : #allocation }
ObjectMemory >> allocateOrRecycleContext: needsLarge [
	"Return a recycled context or a newly allocated one if none is available for recycling."
	| cntxt |
	needsLarge = 0
	ifTrue: [freeContexts ~= NilContext ifTrue:
				[cntxt := freeContexts.
				freeContexts := self fetchPointer: 0 ofObject: cntxt.
				^ cntxt]]
	ifFalse: [freeLargeContexts ~= NilContext ifTrue:
				[cntxt := freeLargeContexts.
				freeLargeContexts := self fetchPointer: 0 ofObject: cntxt.
				^ cntxt]].
	
	needsLarge = 0
		ifTrue: [cntxt := self instantiateContext: (self splObj: ClassMethodContext)
				sizeInBytes: self smallContextSize]
		ifFalse: [cntxt := self instantiateContext: (self splObj: ClassMethodContext)
				sizeInBytes: self largeContextSize].
	"Required init -- above does not fill w/nil.  All others get written."
	self storePointerUnchecked: 4 "InitialIPIndex" ofObject: cntxt
					withValue: nilObj.
	^ cntxt

]

{ #category : #'header access' }
ObjectMemory >> baseHeader: oop [

	^ self longAt: oop
]

{ #category : #constants }
ObjectMemory >> baseHeaderSize [
	"Answer the size of an object memory header word in bytes."

	<inline: true>
	^self cCode: 'BASE_HEADER_SIZE' inSmalltalk: [self bytesPerWord]

]

{ #category : #'garbage collection' }
ObjectMemory >> beRootIfOld: oop [ 
	"If this object is old, mark it as a root (because a new object 
	may be stored into it)"
	<inline: false>
	((self oop: oop isLessThan: youngStart)
			and: [(self isIntegerObject: oop) not])
		ifTrue: ["Yes, oop is an old object"
			self noteAsRoot: oop headerLoc: oop]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> beRootWhileForwarding: oop [
	"Record that the given oop in the old object area points to an object in the young area when oop may be forwarded."
	"Warning: No young objects should be recorded as roots. Callers are responsible for ensuring this constraint is not violated."

	| header fwdBlock |
	header := self longAt: oop.
	(header bitAnd: self markBit) ~= 0
		ifTrue: ["This oop is forwarded"
				fwdBlock := (header bitAnd: self allButMarkBitAndTypeMask) << 1.
				DoAssertionChecks ifTrue: [ self fwdBlockValidate: fwdBlock ].
				self noteAsRoot: oop headerLoc: fwdBlock + self bytesPerWord]
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

{ #category : #'garbage collection' }
ObjectMemory >> biasToGrow [
	| growSize |
	<var: #growSize type: 'usqInt'>
	growSize :=  growHeadroom*3/2 - (self sizeOfFree: freeBlock).
	growSize > 0
		ifTrue: [self growObjectMemory: growSize]
]

{ #category : #'garbage collection' }
ObjectMemory >> biasToGrowCheckGCLimit [
	| growth |
	growth := (youngStart - memory) - gcBiasToGrowThreshold.
	growth < 0 ifTrue: [gcBiasToGrowThreshold := youngStart - memory].
	growth > gcBiasToGrowGCLimit
		 ifTrue: 
			[self fullGC.
			gcBiasToGrowThreshold := youngStart - memory].

					
]

{ #category : #allocation }
ObjectMemory >> bytesLeft: includingSwap [
	^(self sizeOfFree: freeBlock) "already commited"
		+ (self sqMemoryExtraBytesLeft: includingSwap).
]

{ #category : #constants }
ObjectMemory >> bytesPerWord [
	"Answer the size of an object memory word in bytes."

	<inline: true>
	^self
		cCode: 'BYTES_PER_WORD'
		inSmalltalk: [self subclassResponsibility "InterpreterSimulator"]

]

{ #category : #'plugin support' }
ObjectMemory >> characterTable [
	^self splObj: CharacterTable
]

{ #category : #'memory access' }
ObjectMemory >> checkAddress: byteAddress [ 
	"Keep this method around for debugging the C code."
	(self oop: byteAddress isLessThan: self startOfMemory)
		ifTrue: [self error: 'bad address: negative'].
	(self oop: byteAddress isGreaterThanOrEqualTo: memoryLimit)
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
ObjectMemory >> classAlien [
	^self splObj: ClassAlien
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

	^ self longAt: oop - self baseHeaderSize
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

{ #category : #'plugin support' }
ObjectMemory >> classUnsafeAlien [
	^self splObj: ClassUnsafeAlien
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
			oop := rootTable at: i.
			self longAt: oop put: ((self longAt: oop) bitAnd: self allButRootBit).
			rootTable at: i put: 0].
	rootTableCount := 0
]

{ #category : #allocation }
ObjectMemory >> clone: oop [
	"Return a shallow copy of the given object. May cause GC"
	"Assume: Oop is a real object, not a small integer."

	| extraHdrBytes bytes newChunk remappedOop fromIndex toIndex lastFrom newOop header hash |
	<inline: false>
	<var: #lastFrom type: 'usqInt'>
	<var: #fromIndex type: 'usqInt'>
	extraHdrBytes := self extraHeaderBytes: oop.
	bytes := self sizeBitsOf: oop.
	bytes := bytes + extraHdrBytes.

	"allocate space for the copy, remapping oop in case of a GC"
	self pushRemappableOop: oop.
	"check it is safe to allocate this much memory. Return 0 if not"
	(self sufficientSpaceToAllocate: 2500 + bytes) ifFalse:[^0].
	newChunk := self allocateChunk: bytes.
	remappedOop := self popRemappableOop.

	"copy old to new including all header words"
	toIndex := newChunk - self bytesPerWord.  "loop below uses pre-increment"
	fromIndex := (remappedOop - extraHdrBytes) - self bytesPerWord.
	lastFrom := fromIndex + bytes.
	[fromIndex < lastFrom] whileTrue: [
		self longAt: (toIndex := toIndex + self bytesPerWord) put: (self longAt: (fromIndex := fromIndex + self bytesPerWord))].
	newOop := newChunk + extraHdrBytes.  "convert from chunk to oop"

	"fix base header: compute new hash and clear Mark and Root bits"
	hash := self newObjectHash.
	header := (self longAt: newOop) bitAnd: 16r1FFFF.
	"use old ccIndex, format, size, and header-type fields"
	header := header bitOr: ((hash << 17) bitAnd: 16r1FFE0000).
	self longAt: newOop put: header.
	^newOop

]

{ #category : #become }
ObjectMemory >> containOnlyOops: array1 and: array2 [ 
	"Return true if neither array contains a small integer. You 
	can't become: integers!"
	| fieldOffset |
	fieldOffset := self lastPointerOf: array1.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize]
		whileTrue: [(self isIntegerObject: (self longAt: array1 + fieldOffset)) ifTrue: [^ false].
			(self isIntegerObject: (self longAt: array2 + fieldOffset)) ifTrue: [^ false].
			fieldOffset := fieldOffset - self bytesPerWord].
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
	<inline: true>
	<export: true>
	^ headerTypeBytes at: (self headerType: oopOrChunk).
]

{ #category : #'plugin support' }
ObjectMemory >> falseObject [
	^falseObj
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchByte: byteIndex ofObject: oop [

	^ self byteAt: oop + self baseHeaderSize + byteIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchClassOf: oop [ 
	| ccIndex |
	<inline: true>
	(self isIntegerObject: oop) ifTrue: [^ self splObj: ClassInteger].

	ccIndex := (self baseHeader: oop) >> 12 bitAnd: 31.
	ccIndex = 0
		ifTrue: [^ (self classHeader: oop)
				bitAnd: self allButTypeMask]
		ifFalse: ["look up compact class"
			^ self fetchPointer: ccIndex - 1 ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop)]
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchClassOfNonInt: oop [ 
	| ccIndex |
	<inline: true>
	ccIndex := (self baseHeader: oop) >> 12 bitAnd: 31.
	ccIndex = 0
		ifTrue: [^ (self classHeader: oop)
				bitAnd: self allButTypeMask]
		ifFalse: ["look up compact class"
			^ self fetchPointer: ccIndex - 1 ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop)]
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchLong32: fieldIndex ofObject: oop [
	" index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^ self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchLong32LengthOf: objectPointer [
	"Gives size appropriate for, eg, fetchLong32"

	| sz |
	sz := self sizeBitsOf: objectPointer.
	^ (sz - self baseHeaderSize) >> 2
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchPointer: fieldIndex ofObject: oop [
	"index by word size, and return a pointer as long as the word size"

	^ self longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchWordLengthOf: objectPointer [
	"NOTE: this gives size appropriate for fetchPointer: n, but not in general for, eg, fetchLong32, etc."

	| sz |
	sz := self sizeBitsOf: objectPointer.
	^ (sz - self baseHeaderSize) >> self shiftForWord
]

{ #category : #finalization }
ObjectMemory >> finalizeReference: oop [ 
	"During sweep phase we have encountered a weak reference. 
	Check if  its object has gone away (or is about to) and if so, signal a 
	semaphore. "
	"Do *not* inline this in sweepPhase - it is quite an unlikely 
	case to run into a weak reference"
	| weakOop oopGone chunk firstField lastField nonWeakCnt  |
	<inline: false>
	<var: #oop type: 'usqInt'>
	<var: #weakOop type: 'usqInt'>
	nonWeakCnt := self nonWeakFieldsOf: oop.
	firstField := self baseHeaderSize + (nonWeakCnt << self shiftForWord).
	lastField := self lastPointerOf: oop.
	firstField to: lastField by: self bytesPerWord do: [:i | 
			weakOop := self longAt: oop + i.
			"ar 1/18/2005: Added oop < youngStart test to make sure we're not testing
			objects in non-GCable region. This could lead to a forward reference in
			old space with the oop pointed to not being marked and thus treated as free."
			(weakOop == nilObj or: [(self isIntegerObject: weakOop) or:[weakOop < youngStart]])

				ifFalse: ["Check if the object is being collected. 
					If the weak reference points  
					* backward: check if the weakOops chunk is free
					* forward: check if the weakOoop has been marked by GC"
					weakOop < oop
						ifTrue: [chunk := self chunkFromOop: weakOop.
							oopGone := ((self longAt: chunk) bitAnd: TypeMask) = HeaderTypeFree]
						ifFalse: [oopGone := ((self baseHeader: weakOop) bitAnd: self markBit) = 0].
					oopGone ifTrue: ["Store nil in the pointer and signal the  interpreter "
							self longAt: oop + i put: nilObj.
							nonWeakCnt >= 2 ifTrue: [ self weakFinalizerCheck: oop ].
							self signalFinalization: oop]]]
]

{ #category : #'object enumeration' }
ObjectMemory >> firstAccessibleObject [
	"Return the first accessible object in the heap."
	| obj |
	obj := self firstObject.
	[self oop: obj isLessThan: endOfMemory]
		whileTrue: [(self isFreeObject: obj) ifFalse: [^ obj].
			obj := self objectAfter: obj].
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
        7      indexable long (64-bit) fields (only in 64-bit images)
 
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
	compStart := self lowestFreeAfter: self startOfMemory.
	compStart = freeBlock
		ifTrue: ["memory is already compact; only free chunk is at the end "
			^ self initializeMemoryFirstFree: freeBlock].
	(sz := self fwdTableSize: 8) < totalObjectCount
		ifTrue: ["Try to grow OM to make a single pass full GC"
			self growObjectMemory: totalObjectCount - sz + 10000 * 8].
	"work up through memory until all free space is at the end"
	[compStart < freeBlock]
		whileTrue: ["free chunk returned by incCompBody becomes start of next compaction"
			compStart := self incCompBody]
]

{ #category : #'garbage collection' }
ObjectMemory >> fullGC [
	"Do a mark/sweep garbage collection of the entire object memory. Free inaccessible objects but do not move them."

	| startTime |
	<inline: false>
	<var: #startTime type: 'sqLong'>
	DoAssertionChecks ifTrue: [self reverseDisplayFrom: 0 to: 7].
	self preGCAction: true.
	startTime := self ioMicroSecondClock.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self clearRootsTable.
	youngStart := self startOfMemory.  "process all of memory"
	self markPhase.
	"Sweep phase returns the number of survivors.
	Use the up-to-date version instead the one from startup."
	totalObjectCount := self sweepPhase.
	self fullCompaction.
	allocationCount := 0.
	statFullGCs := statFullGCs + 1.
	statGCTime := self ioMicroSecondClock.
	statFullGCMSecs := statFullGCMSecs + (statGCTime - startTime).
	self capturePendingFinalizationSignals.

	youngStart := freeBlock.  "reset the young object boundary"
	self postGCAction.
	DoAssertionChecks ifTrue: [self reverseDisplayFrom: 0 to: 7].

]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdBlockGet: blkSize [
	"Return the address of a two- or four-word forwarding block or nil if no more entries are available."

	fwdTableNext := fwdTableNext + blkSize.
	fwdTableNext <= fwdTableLast
		ifTrue: [ ^ fwdTableNext ]
		ifFalse: [ ^ nil ].  "no more forwarding blocks available"
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdBlockValidate: addr [ 
	"Raise an error if the given address is not a valid forward table entry."
	((self oop: addr isGreaterThan: endOfMemory)
			and: [(self oop: addr isLessThanOrEqualTo: fwdTableNext)
					and: [(addr bitAnd: 3) = 0]])
		ifFalse: [self error: 'invalid fwd table entry']
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdTableInit: blkSize [
	"Set the limits for a table of two- or three-word forwarding blocks above the last used oop. The pointer fwdTableNext moves up to fwdTableLast. Used for compaction of memory and become-ing objects. Returns the number of forwarding blocks available."

	| |
	<inline: false>
	"set endOfMemory to just after a minimum-sized free block"
	self setSizeOfFree: freeBlock to: self baseHeaderSize.
	endOfMemory := freeBlock + self baseHeaderSize.

	"make a fake free chunk at endOfMemory for use as a sentinal in memory scans"
	self setSizeOfFree: endOfMemory to: self baseHeaderSize.

	"use all memory free between freeBlock and memoryLimit for forwarding table"
	"Note: Forward blocks must be quadword aligned."
	fwdTableNext := (endOfMemory + self baseHeaderSize + 7) bitAnd: self wordMask - 7.
	self flag: #Dan.  "Above line does not do what it says (quadword is 16 or 32 bytes)"

	fwdTableLast := memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdTableLast - fwdTableNext) // blkSize  "round down"
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdTableSize: blkSize [
	"Estimate the number of forwarding blocks available for compaction"
	| eom fwdFirst fwdLast |
	<inline: false>

	eom := freeBlock + self baseHeaderSize.
	"use all memory free between freeBlock and memoryLimit for forwarding table"

	"Note: Forward blocks must be quadword aligned."
	fwdFirst := (eom + self baseHeaderSize + 7) bitAnd: self wordMask - 7.
	self flag: #Dan.  "Above line does not do what it says (quadword is 16 or 32 bytes)"

	fwdLast := memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdLast - fwdFirst) // blkSize  "round down"
]

{ #category : #allocation }
ObjectMemory >> growObjectMemory: delta [ 
	"Attempt to grow the object memory by the given delta 
	amount "
	| limit |
	<var: #delta type: 'usqInt'>
	<var: #limit type: 'usqInt'>
	(self isExcessiveAllocationRequest: delta shift: 0) ifFalse: [
		statGrowMemory := statGrowMemory + 1.
		limit := self sqGrowMemory: memoryLimit By: delta.
		limit = memoryLimit
			ifFalse: [memoryLimit := limit - 24.
				"remove a tad for safety"
				self initializeMemoryFirstFree: freeBlock]]
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
	<inline: false>
	"reserve memory for forwarding table"
	self fwdTableInit: self bytesPerWord * 2.  "Two-word blocks"

	"assign new oop locations, reverse their headers, and initialize forwarding blocks"
	bytesFreed := self incCompMakeFwd.

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
	<inline: false>
	bytesFreed := 0.
	oop := self oopFromChunk: compStart.
	[self oop: oop isLessThan: endOfMemory]
		whileTrue: [
				statMkFwdCount := statMkFwdCount + 1.
				(self isFreeObject: oop)
				ifTrue: [bytesFreed := bytesFreed + (self sizeOfFree: oop)]
				ifFalse: ["create a forwarding block for oop"
					fwdBlock := self fwdBlockGet: self bytesPerWord * 2.
					"Two-word block"
					fwdBlock = nil
						ifTrue: ["stop; we have used all available forwarding blocks"
							compEnd := self chunkFromOop: oop.
							^ bytesFreed].
					newOop := oop - bytesFreed.
					self initForwardBlock: fwdBlock mapping: oop to: newOop withBackPtr: false].
			oop := self objectAfterWhileForwarding: oop].
	compEnd := endOfMemory.
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
	<inline: false>
	<var: #firstWord type: 'usqInt'>
	<var: #lastWord type: 'usqInt'>
	<var: #w type: 'usqInt'>
	newOop := nil.
	oop := self oopFromChunk: compStart.
	[self oop: oop isLessThan: compEnd]
		whileTrue: [statCompMoveCount := statCompMoveCount + 1.
			next := self objectAfterWhileForwarding: oop.
			(self isFreeObject: oop)
				ifFalse: ["a moving object; unwind its forwarding block"
					fwdBlock := ((self longAt: oop) bitAnd: self allButMarkBitAndTypeMask) << 1.
					DoAssertionChecks
						ifTrue: [self fwdBlockValidate: fwdBlock].
					newOop := self longAt: fwdBlock.
					header := self longAt: fwdBlock + self bytesPerWord.
					self longAt: oop put: header. "restore the original header"
					bytesToMove := oop - newOop. "move the oop (including any extra header words) "
					sz := self sizeBitsOf: oop.
					firstWord := oop - (self extraHeaderBytes: oop).
					lastWord := oop + sz - self baseHeaderSize.
					target := firstWord - bytesToMove.
					firstWord to: lastWord by: self bytesPerWord
						do: [:w | 
							self longAt: target put: (self longAt: w).
							target := target + self bytesPerWord]].
			oop := next].
	newOop = nil
		ifTrue: ["no objects moved"
			oop := self oopFromChunk: compStart.
			((self isFreeObject: oop) and: [(self objectAfter: oop) = (self oopFromChunk: compEnd)])
				ifTrue: [newFreeChunk := oop]
				ifFalse: [newFreeChunk := freeBlock]]
		ifFalse: ["initialize the newly freed memory chunk"
			"newOop is the last object moved; free chunk starts 
			right after it"
			newFreeChunk := newOop + (self sizeBitsOf: newOop).
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
	| survivorCount startTime weDidGrow |
	<inline: false>
	<var: #startTime type: 'sqLong'>
	rootTableCount >= RootTableSize
		ifTrue: ["root table overflow; cannot do an incremental GC (this should be very rare)"
			statRootTableOverflows := statRootTableOverflows + 1.
			^ self fullGC].
	DoAssertionChecks
		ifTrue: [self reverseDisplayFrom: 8 to: 15.
			self validateRoots; validate].

	self preGCAction: false.
	"incremental GC and compaction"

	startTime := self ioMicroSecondClock.
	weakRootCount := 0.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self markPhase.
	1 to: weakRootCount do:[:i| self finalizeReference: (weakRoots at: i)].
	survivorCount := self sweepPhase.
	self incrementalCompaction.
	statAllocationCount := allocationCount.
	allocationCount := 0.
	statIncrGCs := statIncrGCs + 1.
	statGCTime := self ioMicroSecondClock.
	statIGCDeltaTime := statGCTime - startTime.
	statIncrGCMSecs := statIncrGCMSecs + statIGCDeltaTime.
	self capturePendingFinalizationSignals.

	self forceInterruptCheck. "Force an an interrupt check ASAP.We could choose to be clever here and only do this under certain time conditions. Keep it simple for now"
	
	statRootTableCount  := rootTableCount.
	statSurvivorCount := survivorCount.
	weDidGrow := false.
	(((survivorCount > tenuringThreshold)
			or: [rootTableCount >= RootTableRedZone])
			or: [forceTenureFlag == true])
		ifTrue: ["move up the young space boundary if 
			* there are too many survivors: 
			this limits the number of objects that must be 
			processed on future incremental GC's 
			* we're about to overflow the roots table 
			this limits the number of full GCs that may be caused 
			by root table overflows in the near future"
			forceTenureFlag := false.
			statTenures := statTenures + 1.
			self clearRootsTable.
			(freeBlock < growHeadroom and: 
				[gcBiasToGrow > 0]) 
				ifTrue: [self biasToGrow.
						weDidGrow := true].
			youngStart := freeBlock].
	self postGCAction.
	DoAssertionChecks
		ifTrue: [self validateRoots; validate.
			self reverseDisplayFrom: 8 to: 15].
	weDidGrow ifTrue: [self biasToGrowCheckGCLimit]
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
	<inline: true>
	originalHeader := self longAt: oop.
	DoAssertionChecks
		ifTrue: [fwdBlock = nil ifTrue: [self error: 'ran out of forwarding blocks in become'].
			(originalHeader bitAnd: self markBit) ~= 0
				ifTrue: [self error: 'object already has a forwarding table entry']].
	originalHeaderType := originalHeader bitAnd: TypeMask.
	self longAt: fwdBlock put: newOop.
	self longAt: fwdBlock + self bytesPerWord put: originalHeader.
	backFlag ifTrue: [self longAt: fwdBlock + (self bytesPerWord * 2) put: oop].
	self longAt: oop put: (fwdBlock >> 1 bitOr: (self markBit bitOr: originalHeaderType))
]

{ #category : #'object enumeration' }
ObjectMemory >> initialInstanceOf: classPointer [ 
	"Support for instance enumeration. Return the first instance 
	of the given class, or nilObj if it has no instances."
	| thisObj thisClass |
	thisObj := self firstAccessibleObject.
	[thisObj = nil]
		whileFalse: [thisClass := self fetchClassOf: thisObj.
			thisClass = classPointer ifTrue: [^ thisObj].
			thisObj := self accessibleObjectAfter: thisObj].
	^ nilObj
]

{ #category : #initialization }
ObjectMemory >> initializeMemoryFirstFree: firstFree [ 
	"Initialize endOfMemory to the top of oop storage space, reserving some space for forwarding blocks, and create the freeBlock from which space is allocated. Also create a fake free chunk at endOfMemory to act as a sentinal for memory scans. "
	"Note: The amount of space reserved for forwarding blocks should be chosen to ensure that incremental compactions can usually be done in a single pass. However, there should be enough forwarding blocks so a full compaction can be done in a reasonable number of passes, say ten. (A full compaction requires N object-moving passes, where N = number of non-garbage objects / number of forwarding blocks). 
	di 11/18/2000 Re totalObjectCount: Provide a margin of one byte per object to be used for forwarding pointers at GC time. Since fwd blocks are 8 bytes, this means an absolute worst case of 8 passes to compact memory. In most cases it will be adequate to do compaction in a single pass. "
	| fwdBlockBytes |
	<var: #firstFree type: 'usqInt'>
	<var: #fwdBlockBytes type: 'usqInt'>
	"reserve space for forwarding blocks"
	fwdBlockBytes := totalObjectCount bitAnd: self wordMask - self bytesPerWord + 1.
	(self oop: memoryLimit - fwdBlockBytes isGreaterThanOrEqualTo: firstFree + self baseHeaderSize)
		ifFalse: ["reserve enough space for a minimal free block of BaseHeaderSize bytes"
			fwdBlockBytes := memoryLimit - (firstFree + self baseHeaderSize)].

	"set endOfMemory and initialize freeBlock"
	endOfMemory := memoryLimit - fwdBlockBytes.
	freeBlock := firstFree.
	self setSizeOfFree: freeBlock to: endOfMemory - firstFree. "bytes available for oops"

	"make a fake free chunk at endOfMemory for use as a sentinel in memory scans"
	self setSizeOfFree: endOfMemory to: self baseHeaderSize.
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
	<inline: false>

	"set the start of the young object space"
	youngStart := endOfMemory.

	"image may be at a different address; adjust oops for new location"
	totalObjectCount := self adjustAllOopsBy: bytesToShift.

	self initializeMemoryFirstFree: endOfMemory. "initializes endOfMemory, freeBlock"

	specialObjectsOop := specialObjectsOop + bytesToShift.

	"heavily used special objects"
	nilObj	:= self splObj: NilObject.
	falseObj	:= self splObj: FalseObject.
	trueObj	:= self splObj: TrueObject.

	rootTableCount := 0.
	freeContexts := NilContext.
	freeLargeContexts := NilContext.
	allocationCount := 0.
	lowSpaceThreshold := 0.
	signalLowSpace := false.
	compStart := 0.
	compEnd := 0.
	fwdTableNext := 0.
	fwdTableLast := 0.
	remapBufferCount := 0.
	allocationsBetweenGCs := 4000.  "do incremental GC after this many allocations"
	tenuringThreshold := 2000.  "tenure all suriving objects if count is over this threshold"
	growHeadroom := 4*1024*1024. "four megabyte of headroom when growing"
	shrinkThreshold := 8*1024*1024. "eight megabyte of free space before shrinking"

	"garbage collection statistics"
	statFullGCs := 0.
	statFullGCMSecs := 0.
	statIncrGCs := 0.
	statIncrGCMSecs := 0.
	statTenures := 0.
	statRootTableOverflows := 0.
	statGrowMemory := 0.
	statShrinkMemory := 0.
	forceTenureFlag := 0.
	gcBiasToGrow := 0.
	gcBiasToGrowGCLimit := 0.
	extraRootCount := 0.

]

{ #category : #'object enumeration' }
ObjectMemory >> instanceAfter: objectPointer [ 
	"Support for instance enumeration. Return the next instance 
	of the class of the given object, or nilObj if the enumeration 
	is complete."
	| classPointer thisObj thisClass |
	classPointer := self fetchClassOf: objectPointer.
	thisObj := self accessibleObjectAfter: objectPointer.
	[thisObj = nil]
		whileFalse: [thisClass := self fetchClassOf: thisObj.
			thisClass = classPointer ifTrue: [^ thisObj].
			thisObj := self accessibleObjectAfter: thisObj].
	^ nilObj
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateClass: classPointer indexableSize: size [ 
	"NOTE: This method supports the backward-compatible split instSize field of the 
	class format word. The sizeHiBits will go away and other shifts change by 2 
	when the split fields get merged in an (incompatible) image change."

	| hash header1 header2 cClass byteSize format binc header3 hdrSize fillWord newObj sizeHiBits bm1 classFormat |
	<inline: false>
	DoAssertionChecks ifTrue: [size < 0
				ifTrue: [self error: 'cannot have a negative indexable field count']].
	hash := self newObjectHash.
	classFormat := self formatOfClass: classPointer.
	"Low 2 bits are 0"
	header1 := (classFormat bitAnd: 16r1FF00) bitOr: (hash << HashBitsOffset bitAnd: HashBits).
	header2 := classPointer.
	header3 := 0.
	sizeHiBits := (classFormat bitAnd: 16r60000) >> 9.
	cClass := header1 bitAnd: CompactClassMask. "compact class field from format word"
	byteSize := (classFormat bitAnd: self sizeMask + self size4Bit) + sizeHiBits.
		"size in bytes -- low 2 bits are 0"
	"Note this byteSize comes from the format word of the class which is pre-shifted
		to 4 bytes per field.  Need another shift for 8 bytes per word..."
	byteSize := byteSize << (self shiftForWord - 2).
	format := classFormat >> 8 bitAnd: 15.
	self flag: #sizeLowBits.
	format < 8
		ifTrue:
			[format = 6
				ifTrue: ["long32 bitmaps"
					bm1 := self bytesPerWord - 1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: self longSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: [byteSize := byteSize + (size * self bytesPerWord) "Arrays and 64-bit bitmaps"]
			]
		ifFalse:
			["Strings and Methods"
			bm1 := self bytesPerWord - 1.
			byteSize := byteSize + size + bm1 bitAnd: self longSizeMask. "round up"
			binc := bm1 - (size + bm1 bitAnd: bm1). "odd bytes"
			"low bits of byte size go in format field"
			header1 := header1 bitOr: (binc bitAnd: 3) << 8.
			"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
			header1 := header1 bitOr: (binc bitAnd: 4)].
	byteSize > 255
		ifTrue: ["requires size header word"
			header3 := byteSize.
			header1 := header1]
		ifFalse: [header1 := header1 bitOr: byteSize].
	header3 > 0
		ifTrue: ["requires full header"
			hdrSize := 3]
		ifFalse: [cClass = 0
				ifTrue: [hdrSize := 2]
				ifFalse: [hdrSize := 1]].
	format <= 4
		ifTrue: ["if pointers, fill with nil oop"
			fillWord := nilObj]
		ifFalse: [fillWord := 0].
	newObj := self allocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3 doFill: true with: fillWord.
	^ newObj
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateContext: classPointer sizeInBytes: sizeInBytes [ 
	"This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word."
	| hash header1 header2 hdrSize |
	hash := self newObjectHash.
	header1 := (hash << HashBitsOffset bitAnd: HashBits) bitOr: (self formatOfClass: classPointer).
	header2 := classPointer.
	(header1 bitAnd: CompactClassMask) > 0 "are contexts compact?"
		ifTrue: [hdrSize := 1]
		ifFalse: [hdrSize := 2].
	sizeInBytes <= self sizeMask
		ifTrue: ["OR size into header1.  Must not do this if size > SizeMask"
				header1 := header1 + (sizeInBytes - (header1 bitAnd: self sizeMask))]
		ifFalse: [hdrSize := 3.
				"Zero the size field of header1 if large"
				header1 := header1 - (header1 bitAnd: self sizeMask)].
self flag: #Dan.  "Check details of context sizes"
	^ self allocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: self largeContextSize doFill: false with: 0
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateSmallClass: classPointer sizeInBytes: sizeInBytes [
	"This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include 4 or 8 bytes for the base header word. 
	NOTE this code will only work for sizes that are an integral number of words
		(like not a 32-bit LargeInteger in a 64-bit system). 
	May cause a GC.
	Note that the created small object IS NOT FILLED and must be completed before returning it to Squeak. Since this call is used in routines that do jsut that we are safe. Break this rule and die."

	| hash header1 header2 hdrSize |
	(sizeInBytes bitAnd: (self bytesPerWord - 1)) = 0 ifFalse:
		[self error: 'size must be integral number of words'].
	hash := self newObjectHash.
	header1 := (hash << HashBitsOffset bitAnd: HashBits) bitOr: (self formatOfClass: classPointer).
	header2 := classPointer.
	(header1 bitAnd: CompactClassMask) > 0 "is this a compact class"
		ifTrue: [hdrSize := 1]
		ifFalse: [hdrSize := 2].
	header1 := header1 + (sizeInBytes - (header1 bitAnd: self sizeMask + self size4Bit)).
	^ self allocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: 0 doFill: false with: 0
]

{ #category : #'interpreter access' }
ObjectMemory >> integerObjectOf: value [

	^(value << 1) + 1
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
    "Answer whether the argument object is of compiled method format"
    ^(self formatOf: oop) >= 12
]

{ #category : #allocation }
ObjectMemory >> isExcessiveAllocationRequest: size shift: bits [

	"Answer true if size is greater than (((2 raisedTo: 31) - 1) >> bits). Used
	to limit size of allocation requests to 31 bit integer maximum to prevent
	arithmetic overflow in subsequent calculations. Always answers false
	in interpreter simulation.
	
	In the case of a 64-bit object memory running on a 64-bit host platform,
	allow larger allocation requests.

	Assumes that sizeof(int) is 4 for all platforms."

	| int32 int64 shiftCount |
	<inline: true>
	<var: #int32 type: 'int'> "32 bit signed integer"

	self isDefined: 'SQ_IMAGE64'
		inSmalltalk: [^false]
		comment: 'a 64-bit object memory word size'
		ifTrue: [self isDefined: 'SQ_HOST64'
				inSmalltalk: []
				comment: 'running on a 64-bit host platform'
				ifTrue: ["use 64 bit check if both image and host are 64 bits"
					int64 := size.
					shiftCount := 0.
					int64 < 0 ifTrue: [^ true].
					[shiftCount < bits]
						whileTrue: [int64 := int64 << 1.
							int64 < 0 ifTrue: [^ true].
							shiftCount := shiftCount +1].
					^false]
				ifFalse: ["if sqInt is 64 bit, size parameter may overflow int32"
					size > 16rFFFFFFFF ifTrue: [^false]]]
		ifFalse: ["common case of 32 bit image on either 32 or 64 bit host"
				int32 := size.
				shiftCount := 0.
				int32 < 0 ifTrue: [^ true].
				[shiftCount < bits]
					whileTrue: [int32 := int32 << 1.
						int32 < 0 ifTrue: [^ true].
						shiftCount := shiftCount +1].
				^false]

]

{ #category : #'header access' }
ObjectMemory >> isFreeObject: oop [

	^ (self headerType: oop) = HeaderTypeFree
]

{ #category : #'plugin support' }
ObjectMemory >> isInMemory: address [ 
	"Return true if the given address is in ST object memory"
	^ (self oop: address isGreaterThanOrEqualTo: self startOfMemory)
		and: [self oop: address isLessThan: endOfMemory]
]

{ #category : #'interpreter access' }
ObjectMemory >> isIntegerObject: objectPointer [

	^ (objectPointer bitAnd: 1) > 0
]

{ #category : #'interpreter access' }
ObjectMemory >> isIntegerValue: intValue [
	"Return true if the given value can be represented as a Smalltalk integer value."
	"Use a shift and XOR to set the sign bit if and only if the top two bits of the given
	value are the same, then test the sign bit. Note that the top two bits are equal for
	exactly those integers in the range that can be represented in 31-bits or 63-bits.

	Operands are coerced to machine integer size so the test will work with 64 bit
	images on 32 bit hosts. When running on a 32 bit host, the cast to int has little
	or no performance impact for either 32 bit or 64 bit images.

	On a 64 bit host, the shift and XOR test is replaced by an explicit range check,
	which provides the best performance for both 32 bit and 64 bit images.

	If the range of small integers is enlarged for 64 bit images, this method must
	be updated accordingly."

	^ self isDefined: 'SQ_HOST32'
		inSmalltalk: [true]
		comment: 'cast to int for 64 bit image on 32 bit host'
		ifTrue: ((self cCoerce: intValue to: 'int')
					bitXor: ((self cCoerce: intValue to: 'int') << 1)) >= 0
		ifFalse: (intValue >= 16r-40000000 and: [intValue <= 16r3FFFFFFF])
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonIntegerObject: objectPointer [

	^ (objectPointer bitAnd: 1) = 0
]

{ #category : #'gc -- compaction' }
ObjectMemory >> isObjectForwarded: oop [ 
	"Return true if the given object has a forwarding table entry 
	during a compaction or become operation."
	^ (oop bitAnd: 1) = 0 and: ["(isIntegerObject: oop) not" ((self longAt: oop) bitAnd: self markBit) ~= 0]
]

{ #category : #'interpreter access' }
ObjectMemory >> isOopCompiledMethod: oop [
    "Answer whether the oop is an object of compiled method format"
	<api>
    ^(self isNonIntegerObject: oop) and: [(self formatOf: oop) >= 12]
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
	fmt := self formatOf: oop.
	^ fmt = 6 or: [(fmt >= 8) and: [fmt <= 11]]
]

{ #category : #constants }
ObjectMemory >> largeContextSize [
	"Large contexts have 56 indexable fields.  Max with single header word.
	However note that in 64 bits, for now, large contexts have 3-word headers"

	<inline: true>
	^self
		cCode: 'LARGE_CONTEXT_SIZE'
		inSmalltalk: [ContextFixedSizePlusHeader + 56 * self bytesPerWord]

]

{ #category : #'object enumeration' }
ObjectMemory >> lastPointerOf: oop [ 
	"Return the byte offset of the last pointer field of the given object.  
	Works with CompiledMethods, as well as ordinary objects. 
	Can be used even when the type bits are not correct."
	| fmt sz methodHeader header contextSize |
	<inline: true>
	header := self baseHeader: oop.
	fmt := header >> 8 bitAnd: 15.
	fmt <= 4 ifTrue: [(fmt = 3 and: [self isContextHeader: header])
					ifTrue: ["contexts end at the stack pointer"
						contextSize := self fetchStackPointerOf: oop.
						^ CtxtTempFrameStart + contextSize * self bytesPerWord].
				sz := self sizeBitsOfSafe: oop.
				^ sz - self baseHeaderSize  "all pointers"].
	fmt < 12 ifTrue: [^ 0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	methodHeader := self longAt: oop + self baseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * self bytesPerWord + self baseHeaderSize
]

{ #category : #'gc -- compaction' }
ObjectMemory >> lastPointerWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	the offset of the last pointer in the object in spite of this obstacle. "
	| header fwdBlock fmt size methodHeader contextSize |
	<inline: true>
	header := self longAt: oop.
	(header bitAnd: self markBit) ~= 0
		ifTrue: ["oop is forwarded; get its real header from its forwarding table entry"
			fwdBlock := (header bitAnd: self allButMarkBitAndTypeMask) << 1.
			DoAssertionChecks
				ifTrue: [self fwdBlockValidate: fwdBlock].
			header := self longAt: fwdBlock + self bytesPerWord].
	fmt := header >> 8 bitAnd: 15.
	fmt <= 4
		ifTrue: [(fmt = 3 and: [self isContextHeader: header])
				ifTrue: ["contexts end at the stack pointer"
					contextSize := self fetchStackPointerOf: oop.
					^ CtxtTempFrameStart + contextSize * self bytesPerWord].
			"do sizeBitsOf: using the header we obtained"
			(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
				ifTrue: [size := (self sizeHeader: oop) bitAnd: self allButTypeMask]
				ifFalse: [size := header bitAnd: self sizeMask].
			^ size - self baseHeaderSize].
	fmt < 12 ifTrue: [^ 0]. "no pointers"
	methodHeader := self longAt: oop + self baseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * self bytesPerWord + self baseHeaderSize
]

{ #category : #constants }
ObjectMemory >> longSizeMask [
	"One of the base header word bit fields. For 64-bit word size, lose
	the 4 bit in temp 64-bit chunk format."

	<inline: true>
	^self
		cCode: 'LONG_SIZE_MASK'
		inSmalltalk: [self wordMask - 16rFF + self sizeMask]

]

{ #category : #'garbage collection' }
ObjectMemory >> lowestFreeAfter: chunk [ 
	"Return the first free block after the given chunk in memory."
	| oop oopHeader oopHeaderType oopSize |
	<inline: false>
	oop := self oopFromChunk: chunk.
	[self oop: oop isLessThan: endOfMemory]
		whileTrue: [oopHeader := self baseHeader: oop.
			oopHeaderType := oopHeader bitAnd: TypeMask.
			oopHeaderType = HeaderTypeFree
				ifTrue: [^ oop]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize := (self sizeHeader: oop) bitAnd: self allButTypeMask]
						ifFalse: [oopSize := oopHeader bitAnd: self sizeMask]].
			oop := self oopFromChunk: oop + oopSize].
	self error: 'expected to find at least one free object'
]

{ #category : #'gc -- compaction' }
ObjectMemory >> mapPointersInObjectsFrom: memStart to: memEnd [
	"Use the forwarding table to update the pointers of all non-free objects in the given range of memory. Also remap pointers in root objects which may contains pointers into the given memory range, and don't forget to flush the method cache based on the range"
	| oop |
	<inline: false>
	self compilerMapHookFrom: memStart to: memEnd.
	"update interpreter variables"
	self mapInterpreterOops.
	1 to: extraRootCount do:[:i |
		oop := (extraRoots at: i) at: 0.
		(self isIntegerObject: oop) ifFalse:[(extraRoots at: i) at: 0 put: (self remap: oop)]].
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

	| header lastFieldOffset action statMarkCountLocal |
	header := self longAt: oop.
	(header bitAnd: self markBit) = 0 ifFalse: [^ 0  "already marked"].

	"record tracing status in object's header"
	header := (header bitAnd: self allButTypeMask) bitOr: HeaderTypeGC.
	(self oop: oop isGreaterThanOrEqualTo: youngStart)
		ifTrue: [ header := header bitOr: self markBit ].  "mark only if young"
	self longAt: oop put: header.

	"initialize the tracer state machine"
	parentField := GCTopMarker.
	child := oop.
	(self isWeakNonInt: oop) ifTrue: [
		"Set lastFieldOffset before the weak fields in the receiver"
		lastFieldOffset := (self nonWeakFieldsOf: oop) << self shiftForWord.
		"And remember as weak root"
		weakRootCount := weakRootCount + 1.
		weakRoots at: weakRootCount put: oop.
	] ifFalse: [
		"Do it the usual way"
		lastFieldOffset := self lastPointerOf: oop.
	].
	field := oop + lastFieldOffset.
	action := StartField.
	youngStartLocal := youngStart.
	statMarkCountLocal := statMarkCount.
	"run the tracer state machine until all objects reachable from oop are marked"
	[action = Done] whileFalse: [
		statMarkCountLocal := statMarkCountLocal + 1.
		action = StartField ifTrue: [ action := self startField ].
		action = StartObj ifTrue: [ action := self startObj ].
		action = Upward ifTrue: [ action := self upward ].
	].
	statMarkCount := statMarkCountLocal.
]

{ #category : #constants }
ObjectMemory >> markBit [
	"Top bit"

	<inline: true>
	^self
		cCode: 'MARK_BIT'
		inSmalltalk: [1 bitShift: self bytesPerWord*8 - 1]

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
	<inline: false>
	"clear the recycled context lists"
	freeContexts := NilContext.
	freeLargeContexts := NilContext.
	"trace the interpreter's objects, including the active stack 
	and special objects array"
	self markAndTraceInterpreterOops.
	statSpecialMarkCount := statMarkCount.
	"trace the roots"
	1 to: rootTableCount do: [:i | 
			oop := rootTable at: i.
			self markAndTrace: oop].
	1 to: extraRootCount do:[:i|
			oop := (extraRoots at: i) at: 0.
			(self isIntegerObject: oop) ifFalse:[self markAndTrace: oop]].

]

{ #category : #'header access' }
ObjectMemory >> newObjectHash [
	"Answer a new 16-bit pseudo-random number for use as an identity hash."

	lastHash := 13849 + (27181 * lastHash) bitAnd: 65535.
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
	<inline: true>
	header := self longAt: headerLoc.
	(header bitAnd: self rootBit) = 0
		ifTrue: ["record oop as root only if not already recorded"
			rootTableCount < RootTableRedZone
				ifTrue: ["record root if there is enough room in the roots 
					table "
					rootTableCount := rootTableCount + 1.
					rootTable at: rootTableCount put: oop.
					self longAt: headerLoc put: (header bitOr: self rootBit)]
				ifFalse: ["we're getting in the red zone"
					rootTableCount < RootTableSize
						ifTrue: ["but there's still space to record it"
							rootTableCount := rootTableCount + 1.
							rootTable at: rootTableCount put: oop.
							self longAt: headerLoc put: (header bitOr: self rootBit).
							"but force an IGC on the next allocation"
							allocationCount := allocationsBetweenGCs + 1]]]
]

{ #category : #'object enumeration' }
ObjectMemory >> objectAfter: oop [ 
	"Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete."
	| sz |
	<inline: true>
	DoAssertionChecks
		ifTrue: [(self oop: oop isGreaterThanOrEqualTo:endOfMemory)
					ifTrue: [self error: 'no objects after the end of memory']].
	(self isFreeObject: oop)
		ifTrue: [sz := self sizeOfFree: oop]
		ifFalse: [sz := self sizeBitsOf: oop].
	^ self oopFromChunk: oop + sz
]

{ #category : #'gc -- compaction' }
ObjectMemory >> objectAfterWhileForwarding: oop [
	"Return the oop of the object after the given oop when the actual header of the oop may be in the forwarding table."

	| header fwdBlock realHeader sz |
	<inline: true>
	header := self longAt: oop.
	(header bitAnd: self markBit) = 0 ifTrue: [ ^ self objectAfter: oop ].  "oop not forwarded"

	"Assume: mark bit cannot be set on a free chunk, so if we get here,
	 oop is not free and it has a forwarding table entry"

	fwdBlock := (header bitAnd: self allButMarkBitAndTypeMask) << 1.
	DoAssertionChecks ifTrue: [ self fwdBlockValidate: fwdBlock ].
	realHeader := self longAt: fwdBlock + self bytesPerWord.
	"following code is like sizeBitsOf:"
	(realHeader bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: self longSizeMask ]
		ifFalse: [ sz := realHeader bitAnd: self sizeMask ].

	^ self oopFromChunk: (oop + sz)
]

{ #category : #'interpreter access' }
ObjectMemory >> obsoleteDontUseThisFetchWord: fieldIndex ofObject: oop [
	"This message is deprecated but supported for a while via a tweak to sqVirtualMachine.[ch] Use fetchLong32, fetchLong64 or fetchPointer instead for new code"

	^self fetchLong32: fieldIndex ofObject: oop
]

{ #category : #'oop comparison' }
ObjectMemory >> oop: anOop isGreaterThan: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."

	^ (self cCoerce: anOop to: #usqInt)
		> (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
ObjectMemory >> oop: anOop isGreaterThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."

	^ (self cCoerce: anOop to: #usqInt)
		>= (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
ObjectMemory >> oop: anOop isLessThan: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."

	^ (self cCoerce: anOop to: #usqInt)
		< (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
ObjectMemory >> oop: anOop isLessThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."

	^ (self cCoerce: anOop to: #usqInt)
		<= (self cCoerce: otherOop to: #usqInt)
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
	oop := remapBuffer at: remapBufferCount.
	remapBufferCount := remapBufferCount - 1.
	^ oop
]

{ #category : #'garbage collection' }
ObjectMemory >> possibleRootStoreInto: oop value: valueObj [ 
	"oop is an old object. If valueObj is young, mark the object as a root."

	<inline: false>
	((self oop: valueObj isGreaterThanOrEqualTo: youngStart)
			and: [(self isIntegerObject: valueObj) not])
		ifTrue: ["Yes, valueObj is a young object"
				self noteAsRoot: oop headerLoc: oop]
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

	"Important note on multiple references to same object  - since the preparation of
	fwdBlocks is NOT idempotent we get VM crashes if the same object is referenced more
	than once in such a way as to require multiple fwdBlocks.
	oop1 forwardBecome: oop1 is ok since only a single fwdBlock is needed.
	oop1 become: oop1 would fail because the second fwdBlock woudl not have the actual object
	header but rather the mutated ref to the first fwdBlock.
	Further problems can arise with an array1 or array2 that refer multiply to the same 
	object. This would notbe expected input for programmer writen code but might arise from
	automatic usage such as in ImageSegment loading.
	To avoid the simple and rather common case of oop1 become*: oop1, we skip such pairs
	and simply avoid making fwdBlocks - it is redundant anyway"
	| entriesNeeded entriesAvailable fieldOffset oop1 oop2 fwdBlock fwdBlkSize |
	entriesNeeded := (self lastPointerOf: array1) // self bytesPerWord. "need enough entries for all oops"
	"Note: Forward blocks must be quadword aligned - see fwdTableInit:."
	twoWayFlag
		ifTrue: ["Double the number of blocks for two-way become"
			entriesNeeded := entriesNeeded * 2.
			fwdBlkSize := self bytesPerWord * 2]
		ifFalse: ["One-way become needs backPointers in fwd blocks."
			fwdBlkSize := self bytesPerWord * 4].
	entriesAvailable := self fwdTableInit: fwdBlkSize.
	entriesAvailable < entriesNeeded
		ifTrue: [self initializeMemoryFirstFree: freeBlock.
			"re-initialize the free block"
			^ false].
	fieldOffset := self lastPointerOf: array1.
	[fieldOffset >= self baseHeaderSize]
		whileTrue: [oop1 := self longAt: array1 + fieldOffset.
			oop2 := self longAt: array2 + fieldOffset.
			"if oop1 == oop2, no need to do any work for this pair.
			May still be other entries in the arrays though so keep looking"
			oop1 = oop2
				ifFalse: [fwdBlock := self fwdBlockGet: fwdBlkSize.
					self
						initForwardBlock: fwdBlock
						mapping: oop1
						to: oop2
						withBackPtr: twoWayFlag not.
					twoWayFlag
						ifTrue: ["Second block maps oop2 back to oop1 for two-way become"
							fwdBlock := self fwdBlockGet: fwdBlkSize.
							self
								initForwardBlock: fwdBlock
								mapping: oop2
								to: oop1
								withBackPtr: twoWayFlag not]].
			fieldOffset := fieldOffset - self bytesPerWord].
	^ true
]

{ #category : #'interpreter access' }
ObjectMemory >> pushRemappableOop: oop [
	"Record the given object in a the remap buffer. Objects in this buffer are remapped when a compaction occurs. This facility is used by the interpreter to ensure that objects in temporary variables are properly remapped."

	remapBuffer at: (remapBufferCount := remapBufferCount + 1) put: oop.
]

{ #category : #allocation }
ObjectMemory >> recycleContextIfPossible: cntxOop [ 
	"If possible, save the given context on a list of free contexts to 
	be recycled."
	"Note: The context is not marked free, so it can be reused 
	with minimal fuss. The recycled context lists are cleared at 
	every garbage collect."
	| header |
	<inline: true>
	"only recycle young contexts (which should be most of them)"
	(self oop: cntxOop isGreaterThanOrEqualTo: youngStart)
		ifTrue: [header := self baseHeader: cntxOop.
			(self isMethodContextHeader: header)
				ifTrue: ["It's a young context, alright."
					(header bitAnd: self sizeMask) = self smallContextSize
						ifTrue: ["Recycle small contexts"
							self storePointerUnchecked: 0 ofObject: cntxOop withValue: freeContexts.
							freeContexts := cntxOop].
					(header bitAnd: self sizeMask) = self largeContextSize
						ifTrue: ["Recycle large contexts"
							self storePointerUnchecked: 0 ofObject: cntxOop withValue: freeLargeContexts.
							freeLargeContexts := cntxOop]]]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remap: oop [ 
	"Map the given oop to its new value during a compaction or 
	become: operation. If it has no forwarding table entry, 
	return the oop itself."
	| fwdBlock |
	<inline: false>
	(self isObjectForwarded: oop)
		ifTrue: ["get the new value for oop from its forwarding block"
			fwdBlock := ((self longAt: oop) bitAnd: self allButMarkBitAndTypeMask) << 1.
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

	classHeader := self longAt: oop - self bytesPerWord.
	classOop := classHeader bitAnd: self allButTypeMask.
	(self isObjectForwarded: classOop)
		ifTrue: [fwdBlock := ((self longAt: classOop) bitAnd: self allButMarkBitAndTypeMask) << 1.
			DoAssertionChecks
				ifTrue: [self fwdBlockValidate: fwdBlock].
			newClassOop := self longAt: fwdBlock.
			newClassHeader := newClassOop bitOr: (classHeader bitAnd: TypeMask).
			self longAt: oop - self bytesPerWord put: newClassHeader.
			"The following ensures that become: into an old object's class makes it a root. 
			It does nothing during either incremental or full compaction because 
			oop will never be < youngStart."
			((self oop: oop isLessThan: youngStart)
					and: [self oop: newClassOop isGreaterThanOrEqualTo: youngStart])
				ifTrue: [self beRootWhileForwarding: oop]]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remapFieldsAndClassOf: oop [ 
	"Replace all forwarded pointers in this object with their new oops, using the forwarding table. Remap its class as well, if 
	necessary. "
	"Note: The given oop may be forwarded itself, which means that its real header is in its forwarding table entry."
	| fieldOffset fieldOop fwdBlock newOop |
	<inline: true>
	fieldOffset := self lastPointerWhileForwarding: oop.
	[fieldOffset >= self baseHeaderSize]
		whileTrue: [fieldOop := self longAt: oop + fieldOffset.
			(self isObjectForwarded: fieldOop)
				ifTrue: ["update this oop from its forwarding block"
					fwdBlock := ((self longAt: fieldOop) bitAnd: self allButMarkBitAndTypeMask) << 1.
					DoAssertionChecks
						ifTrue: [self fwdBlockValidate: fwdBlock].
					newOop := self longAt: fwdBlock.
					self longAt: oop + fieldOffset put: newOop.
					"The following ensures that become: into old object makes it a root. 
					It does nothing during either incremental or full compaction because 
					oop will never be < youngStart."
					((self oop: oop isLessThan: youngStart)
							and: [self oop: newOop isGreaterThanOrEqualTo: youngStart])
						ifTrue: [self beRootWhileForwarding: oop]].
			fieldOffset := fieldOffset - self bytesPerWord].
	self remapClassOf: oop
]

{ #category : #'plugin support' }
ObjectMemory >> removeGCRoot: varLoc [
	"Remove the given variable location to the extra roots table"
	| root |
	<export: true>
	<var: #varLoc declareC: 'sqInt *varLoc'>
	<var: #root declareC: 'sqInt *root'>
	1 to: extraRootCount do:[:i|
		root := extraRoots at: i.
		root == varLoc ifTrue:["swap varLoc with last entry"
			extraRoots at: i put: (extraRoots at: extraRootCount).
			extraRootCount := extraRootCount-1.
			^true]].
	^false "not found"
]

{ #category : #become }
ObjectMemory >> restoreHeaderOf: oop [ 
	"Restore the original header of the given oop from its 
	forwarding block."
	| fwdHeader fwdBlock |
	fwdHeader := self longAt: oop.
	fwdBlock := (fwdHeader bitAnd: self allButMarkBitAndTypeMask) << 1.
	DoAssertionChecks
		ifTrue: [(fwdHeader bitAnd: self markBit) = 0
				ifTrue: [self error: 'attempting to restore the header of an object that has no forwarding block'].
			self fwdBlockValidate: fwdBlock].
	self longAt: oop put: (self longAt: fwdBlock + self bytesPerWord)
]

{ #category : #become }
ObjectMemory >> restoreHeadersAfterBecoming: list1 with: list2 [ 
	"Restore the headers of all oops in both lists. Exchange their hash bits so
	becoming objects in identity sets and dictionaries doesn't change their
	hash value."
	"See also prepareForwardingTableForBecoming:with:woWay: for notes
	regarding the case
	of oop1 = oop2"
	| fieldOffset oop1 oop2 hdr1 hdr2 |
	fieldOffset := self lastPointerOf: list1.
	[fieldOffset >= self baseHeaderSize]
		whileTrue: [oop1 := self longAt: list1 + fieldOffset.
			oop2 := self longAt: list2 + fieldOffset.
			oop1 = oop2
				ifFalse: [self restoreHeaderOf: oop1.
					self restoreHeaderOf: oop2.
					"Exchange hash bits of the two objects."
					hdr1 := self longAt: oop1.
					hdr2 := self longAt: oop2.
					self
						longAt: oop1
						put: ((hdr1 bitAnd: self allButHashBits) bitOr: (hdr2 bitAnd: HashBits)).
					self
						longAt: oop2
						put: ((hdr2 bitAnd: self allButHashBits) bitOr: (hdr1 bitAnd: HashBits))].
			fieldOffset := fieldOffset - self bytesPerWord]
]

{ #category : #become }
ObjectMemory >> restoreHeadersAfterForwardBecome: copyHashFlag [ 
	"Forward become leaves us with no original oops in the 
	mutated object list, 
	so we must enumerate the (four-word) forwarding blocks 
	where we have stored backpointers."
	"This loop start is copied from fwdTableInit:"
	| oop1 fwdBlock oop2 hdr1 hdr2 |
	fwdBlock := endOfMemory + self baseHeaderSize + 7 bitAnd: self wordMask - 7.
	self flag: #Dan.  "See flag comment in fwdTableInit: (dtl)"
	fwdBlock := fwdBlock + (self bytesPerWord * 4).
	"fwdBlockGet: did a pre-increment"
	[self oop: fwdBlock isLessThanOrEqualTo: fwdTableNext
	"fwdTableNext points to the last active block"]
		whileTrue: [oop1 := self longAt: fwdBlock + (self bytesPerWord * 2).
			"Backpointer to mutated object."
			oop2 := self longAt: fwdBlock.
			self restoreHeaderOf: oop1.
			copyHashFlag
				ifTrue: ["Change the hash of the new oop (oop2) to be that of the old (oop1) 
					so mutated objects in hash structures will be 
					happy after the change."
					hdr1 := self longAt: oop1.
					hdr2 := self longAt: oop2.
					self longAt: oop2 put: ((hdr2 bitAnd: self allButHashBits) bitOr: (hdr1 bitAnd: HashBits))].
			fwdBlock := fwdBlock + (self bytesPerWord * 4)]
]

{ #category : #'header access' }
ObjectMemory >> rightType: headerWord [
	"Compute the correct header type for an object based on the size and compact class fields of the given base header word, rather than its type bits. This is used during marking, when the header type bits are used to record the state of tracing."

	(headerWord bitAnd: self sizeMask) = 0  "zero size field in header word"
		ifTrue: [ ^HeaderTypeSizeAndClass ]
		ifFalse: [ (headerWord bitAnd: CompactClassMask) = 0
				ifTrue: [ ^HeaderTypeClass ]
				ifFalse: [ ^HeaderTypeShort ]].
]

{ #category : #constants }
ObjectMemory >> rootBit [
	"Next-to-Top bit"

	<inline: true>
	^self
		cCode: 'ROOT_BIT'
		inSmalltalk: [1 bitShift: self bytesPerWord * 8 - 2]

]

{ #category : #'header access' }
ObjectMemory >> setSizeOfFree: chunk to: byteSize [
	"Set the header of the given chunk to make it be a free chunk of the given size."

	self longAt: chunk put: ((byteSize bitAnd: self allButTypeMask) bitOr: HeaderTypeFree).
]

{ #category : #constants }
ObjectMemory >> shiftForWord [

	<inline: true>
	^self
		cCode: 'SHIFT_FOR_WORD'
		inSmalltalk: [(self bytesPerWord log: 2) rounded]

]

{ #category : #allocation }
ObjectMemory >> shrinkObjectMemory: delta [ 
	"Attempt to shrink the object memory by the given delta 
	amount "
	| limit |
	statShrinkMemory := statShrinkMemory + 1. 
	limit := self sqShrinkMemory: memoryLimit By: delta.
	limit = memoryLimit
		ifFalse: [memoryLimit := limit - 24.
			"remove a tad for safety"
			self initializeMemoryFirstFree: freeBlock]
]

{ #category : #constants }
ObjectMemory >> size4Bit [
	"One of the base header word bit fields. The 4 bit is excluded from sizeMask for
	64-bit object memory, but need it for ST size.
	Note SizeMask + Size4Bit gives the mask needed for size fits of format word in classes.
	This is used in instantiateClass:indexableSize: "

	<inline: true>
	^self
		cCode: 'SIZE_4_BIT'
		inSmalltalk: [self bytesPerWord = 4
			ifTrue: [0]
			ifFalse: [4]]

]

{ #category : #'header access' }
ObjectMemory >> sizeBitsOf: oop [
	"Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words."
	"Note: byte indexable objects need to have low bits subtracted from this size."

	| header |
	header := self baseHeader: oop.
	(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: self longSizeMask ]
		ifFalse: [ ^ header bitAnd: self sizeMask ].
]

{ #category : #'header access' }
ObjectMemory >> sizeBitsOfSafe: oop [
	"Compute the size of the given object from the cc and size fields in its header. This works even if its type bits are not correct."

	| header type |
	header := self baseHeader: oop.
	type := self rightType: header.
	type = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: self allButTypeMask ]
		ifFalse: [ ^ header bitAnd: self sizeMask ].
]

{ #category : #'header access' }
ObjectMemory >> sizeHeader: oop [

	^ self longAt: oop - (self bytesPerWord * 2)
]

{ #category : #constants }
ObjectMemory >> sizeMask [
	"One of the base header word bit fields. For 64-bit word size, lose the 4 bit
	in temp 64-bit chunk format. See size4Bit, which restores the 4 bit ST size.
	Note SizeMask + Size4Bit gives the mask needed for size fits of format word in classes.
	This is used in instantiateClass:indexableSize: "

	<inline: true>
	^self
		cCode: 'SIZE_MASK'
		inSmalltalk: [self bytesPerWord = 4
			ifTrue: [16rFC]
			ifFalse: [16rF8  "Lose the 4 bit in temp 64-bit chunk format"]]

]

{ #category : #'header access' }
ObjectMemory >> sizeOfFree: oop [
	"Return the size of the given chunk in bytes. Argument MUST be a free chunk."
	<returnTypeC: 'usqInt'>
	^ (self longAt: oop) bitAnd: self allButTypeMask
]

{ #category : #constants }
ObjectMemory >> smallContextSize [
	"16 indexable fields, calculated as ContextFixedSizePlusHeader + 16 * BytesPerWord"

	<inline: true>
	^self
		cCode: 'SMALL_CONTEXT_SIZE'
		inSmalltalk: [ContextFixedSizePlusHeader + 16 * self bytesPerWord]

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
	<inline: true>
	child := self longAt: field.
	typeBits := child bitAnd: TypeMask.
	(typeBits bitAnd: 1) = 1
		ifTrue: ["field contains a SmallInteger; skip it"
			field := field - self bytesPerWord.
			^ StartField].
	typeBits = 0 ifTrue: ["normal oop, go down"
			self longAt: field put: parentField.
			parentField := field.
			^ StartObj].
	typeBits = 2 ifTrue: ["reached the header; do we need to process the class word? "
			(child bitAnd: CompactClassMask) ~= 0
				ifTrue: ["object's class is compact; we're done"
					"restore the header type bits"
					child := child bitAnd: self allButTypeMask.
					childType := self rightType: child.
					self longAt: field put: (child bitOr: childType).
					^ Upward]
				ifFalse: ["object has a full class word; process that class"
					child := self longAt: field - self bytesPerWord. "class word"
					child := child bitAnd: self allButTypeMask. "clear type bits"
					self longAt: field - self bytesPerWord put: parentField.
					parentField := field - self bytesPerWord bitOr: 1.
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
	<inline: true>
	oop := child.
	(self oop: oop isLessThan: youngStartLocal)
		ifTrue: ["old object; skip it"
			field := oop.
			^ Upward].
	header := self longAt: oop.
	(header bitAnd: self markBit) = 0
		ifTrue: ["unmarked; mark and trace"
			"Do not trace the object's indexed fields if it's a weak class "
			(self isWeakNonInt: oop)
				ifTrue: ["Set lastFieldOffset before the weak fields in the receiver "
					lastFieldOffset := (self nonWeakFieldsOf: oop) << self shiftForWord]
				ifFalse: ["Do it the usual way"
					lastFieldOffset := self lastPointerOf: oop].
			header := header bitAnd: self allButTypeMask.
			header := (header bitOr: self markBit) bitOr: HeaderTypeGC.
			self longAt: oop put: header.
			field := oop + lastFieldOffset.
			^ StartField "trace its fields and class"]
		ifFalse: ["already marked; skip it"
			field := oop.
			^ Upward]
]

{ #category : #'object enumeration' }
ObjectMemory >> startOfMemory [
	"Return the start of object memory."

	^memory
]

{ #category : #'interpreter access' }
ObjectMemory >> storeByte: byteIndex ofObject: oop withValue: valueByte [

	^ self byteAt: oop + self baseHeaderSize + byteIndex
		put: valueByte
]

{ #category : #'interpreter access' }
ObjectMemory >> storeLong32: fieldIndex ofObject: oop withValue: valueWord [

	^ self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
		put: valueWord
]

{ #category : #'interpreter access' }
ObjectMemory >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."

	(self oop: oop isLessThan: youngStart) ifTrue: [
		self possibleRootStoreInto: oop value: valuePointer.
	].

	^ self longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'interpreter access' }
ObjectMemory >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	"Like storePointer:ofObject:withValue:, but the caller guarantees that the object being stored into is a young object or is already marked as a root."

	^ self longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
			put: valuePointer

]

{ #category : #'interpreter access' }
ObjectMemory >> storeWord: fieldIndex ofObject: oop withValue: valueWord [
	"This message is deprecated.  Use storeLong32, storeLong64 or storePointer"

	self abort
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceAfterGC: minFree [ 
	"Return true if there is enough free space after doing a garbage collection. If not, signal that space is low."
	| growSize minFreePlus |
	<inline: false>
	<var: #minFree type: 'usqInt'>
	<var: #growSize type: 'usqInt'>
	<var: #minFreePlus type: 'usqInt'>

	self incrementalGC. "try to recover some space"

	(self oop: (self sizeOfFree: freeBlock) isLessThan: minFree)
		ifTrue: [signalLowSpace ifTrue: [^false]. "give up; problem is already noted"
			self fullGC. "try harder"
			"for stability, require more free space after doing an expensive full GC"
			minFreePlus := minFree + 15000.
			minFreePlus < minFree
				ifTrue: [^ false "arithmetic overflow"].
			(self oop: (self sizeOfFree: freeBlock) isGreaterThanOrEqualTo: minFreePlus)
				ifTrue: [^ true].

			"still not enough; attempt to grow object memory"
			growSize := minFree - (self sizeOfFree: freeBlock) + growHeadroom.
			self growObjectMemory: growSize.

			(self oop: (self sizeOfFree: freeBlock) isGreaterThanOrEqualTo: minFreePlus)
				ifTrue: [^true].

			"still not enough"
			^false].
	^true
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceToAllocate: bytes [
	"Return true if there is enough space to allocate the given number of bytes,
	perhaps after doing a garbage collection. Sender is responsible for ensuring
	that requested size does result in arithmetic overflow, see note below."

	| minFree |
	<inline: true>
	<var: #bytes type: 'usqInt'>
	<var: #minFree type: 'usqInt'>

	"Note: Arithmetic overflow may occur in calculation of minFree (indicated by
	minFree < bytes after calculation of minFree). The check is performed by sender
	to avoid redundant test here."
	minFree := lowSpaceThreshold + bytes + self baseHeaderSize.

	"check for low-space"
	(self oop: (self sizeOfFree: freeBlock) isGreaterThanOrEqualTo: minFree)
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
	<inline: false>
	<var: #oop type: 'usqInt'>
	<var: #endOfMemoryLocal type: 'usqInt'>
	entriesAvailable := self fwdTableInit: self bytesPerWord * 2.
	survivors := 0.
	freeChunk := -1. "an invalid object pointer, note that 0 may refer to a meaningful slot"
	firstFree := -1.
	"will be updated later"
	endOfMemoryLocal := endOfMemory.
	oop := self oopFromChunk: youngStart.
	[oop < endOfMemoryLocal]
		whileTrue: ["get oop's header, header type, size, and header size"
			statSweepCount := statSweepCount + 1.
			oopHeader := self baseHeader: oop.
			oopHeaderType := oopHeader bitAnd: TypeMask.
			hdrBytes := headerTypeBytes at: oopHeaderType.
			(oopHeaderType bitAnd: 1) = 1
				ifTrue: [oopSize := oopHeader bitAnd: self sizeMask]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize := (self sizeHeader: oop) bitAnd: self longSizeMask]
						ifFalse: ["free chunk" oopSize := oopHeader bitAnd: self longSizeMask]].
			(oopHeader bitAnd: self markBit) = 0
				ifTrue: ["object is not marked; free it"
					"<-- Finalization support: We need to mark each oop chunk as free -->"
					self longAt: oop - hdrBytes put: HeaderTypeFree.
					freeChunk ~= -1
						ifTrue: ["enlarge current free chunk to include this oop"
							freeChunkSize := freeChunkSize + oopSize + hdrBytes]
						ifFalse: ["start a new free chunk"
							freeChunk := oop - hdrBytes.
							"chunk may start 4 or 8 bytes before oop"
							freeChunkSize := oopSize + (oop - freeChunk).
							"adjust size for possible extra header bytes"
							firstFree = -1 ifTrue: [firstFree := freeChunk]]]
				ifFalse: ["object is marked; clear its mark bit and possibly adjust 
					the compaction start"
					self longAt: oop put: (oopHeader bitAnd: self allButMarkBit).
					"<-- Finalization support: Check if we're running about a weak class -->"
					(self isWeakNonInt: oop) ifTrue: [self finalizeReference: oop].
					entriesAvailable > 0
						ifTrue: [entriesAvailable := entriesAvailable - 1]
						ifFalse: ["start compaction at the last free chunk before this object"
							firstFree := freeChunk].
					freeChunk ~= -1
						ifTrue: ["record the size of the last free chunk"
							self longAt: freeChunk put: ((freeChunkSize bitAnd: self longSizeMask) bitOr: HeaderTypeFree).
							freeChunk := -1].
					survivors := survivors + 1].
			oop := self oopFromChunk: oop + oopSize].
	freeChunk ~= -1
		ifTrue: ["record size of final free chunk"
			self longAt: freeChunk put: ((freeChunkSize bitAnd: self longSizeMask) bitOr: HeaderTypeFree)].
	oop = endOfMemory
		ifFalse: [self error: 'sweep failed to find exact end of memory'].
	firstFree = -1
		ifTrue: [self error: 'expected to find at least one free object']
		ifFalse: [compStart := firstFree].

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
	<inline: false>
	oop := self oopFromChunk: memStart.
	[self oop: oop isLessThan: memEnd]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [self remapFieldsAndClassOf: oop].
			oop := self objectAfterWhileForwarding: oop]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> updatePointersInRootObjectsFrom: memStart to: memEnd [ 
	"update pointers in root objects"
	| oop |
	<inline: false>
	1 to: rootTableCount do: [:i | 
			oop := rootTable at: i.
			((self oop: oop isLessThan: memStart)
					or: [self oop: oop isGreaterThanOrEqualTo: memEnd])
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
	<inline: true>
	(parentField bitAnd: 1) = 1
		ifTrue: [parentField = GCTopMarker
				ifTrue: ["top of the chain"
					header := (self longAt: field) bitAnd: self allButTypeMask.
					type := self rightType: header.
					self longAt: field put: (header bitOr: type). "install type on class oop"
					^ Done]
				ifFalse: ["was working on the extended class word"
					child := field. "oop of class"
					field := parentField - 1. "class word, ** clear the low bit **"
					parentField := self longAt: field.
					header := self longAt: field + self bytesPerWord. "base header word"
					type := self rightType: header.
					self longAt: field put: (child bitOr: type). "install type on class oop"
					field := field + self bytesPerWord. "point at header"
					"restore type bits"
					header := header bitAnd: self allButTypeMask.
					self longAt: field put: (header bitOr: type).
					^ Upward]]
		ifFalse: ["normal"
			child := field. "who we worked on below"
			field := parentField. "where to put it"
			parentField := self longAt: field.
			self longAt: field put: child.
			field := field - self bytesPerWord. "point at header"
			^ StartField]
]

{ #category : #'memory access' }
ObjectMemory >> validate [
"null method just to stop compilation of interp.c from barfing"
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
	<var: #oop type: 'usqInt'>
	<var: #fieldAddr type: 'usqInt'>
	<var: #fieldOop type: 'usqInt'>
	badRoot := false.
	oop := self firstObject.

	[oop < youngStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[fieldAddr := oop + (self lastPointerOf: oop).
			[fieldAddr > oop] whileTrue:
				[fieldOop := self longAt: fieldAddr.
				(fieldOop >= youngStart and: [(self isIntegerObject: fieldOop) not]) ifTrue:
					["fieldOop is a pointer to a young object"
					header := self longAt: oop.
					(header bitAnd: self rootBit) = 0
					ifTrue:
						["Forbidden: points to young obj but root bit not set."
						DoAssertionChecks ifTrue: [self error: 'root bit not set'].
						badRoot := true]
					ifFalse:
						["Root bit is set"
						"Extreme test -- validate that oop was entered in rootTable too..."
						"Disabled for now...
						found := false.
						1 to: rootTableCount do:
							[:i | oop = (rootTable at: i) ifTrue: [found := true]].
						found ifFalse:
							[DoAssertionChecks ifTrue: [self error: 'root table not set'].
							badRoot := true].
						..."
						]].
				fieldAddr := fieldAddr - self bytesPerWord]].
		oop := self objectAfter: oop].
	^ badRoot
]

{ #category : #finalization }
ObjectMemory >> weakFinalizerCheck: oop [
	"Our oop has at least 2 non-weak fixed slots (this is assured before entering this method, in
	#finalizeReference:.
	We are assuming that if its first non-weak field is an instance of WeakFinalizer class,
	then we should add this oop to that list, by storing it to list's first field and
	also, updating the oop's 2nd fixed slot to point to the value which we overridden:
	
	list := oop instVarAt: 1.
	list class == WeakFinalizer ifTrue: [
		first := list instVarAt: 1.
		oop instVarAt: 2 put: first.
		list instVarAt: 1 put: oop ]	"

	| listOop listItemOop |
	<inline: true>
	
	listOop := self fetchPointer: 0 ofObject: oop.
	(self fetchClassOf: listOop) == (self splObj: ClassWeakFinalizer) ifTrue: [
		listItemOop := self fetchPointer: 0 ofObject: listOop.
		self storePointer: 1 ofObject: oop withValue: listItemOop. 
		self storePointer: 0 ofObject: listOop withValue: oop.
	].

]

{ #category : #constants }
ObjectMemory >> wordMask [
	"Answer a bit mask for an object word, either 32 or 64 bits."

	<inline: true>
	^self
		cCode: 'WORD_MASK'
		inSmalltalk: [(1 bitShift: self bytesPerWord * 8) - 1]

]
