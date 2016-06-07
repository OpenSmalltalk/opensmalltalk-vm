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
	#superclass : #VMClass,
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
		'rootTableOverflowed',
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
		'gcBiasToGrow',
		'gcBiasToGrowGCLimit',
		'gcBiasToGrowThreshold',
		'statFullGCs',
		'statIncrGCs',
		'statFullGCUsecs',
		'statIncrGCUsecs',
		'statGCEndTime',
		'statIGCDeltaUsecs',
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
		'statMarkCountLocal',
		'statSweepCount',
		'statMkFwdCount',
		'statCompMoveCount',
		'statGrowMemory',
		'statShrinkMemory',
		'statRootTableCount',
		'statAllocationCount',
		'statSurvivorCount',
		'statSpecialMarkCount',
		'forceTenureFlag',
		'gcStartUsecs'
	],
	#classVars : [
		'AllButHashBits',
		'AllButImmutabilityBit',
		'AllButMarkBit',
		'AllButMarkBitAndTypeMask',
		'AllButRootBit',
		'Done',
		'ExtraRootSize',
		'GCTopMarker',
		'HashBits',
		'HeaderTypeClass',
		'HeaderTypeExtraBytes',
		'HeaderTypeFree',
		'HeaderTypeGC',
		'LongSizeNumBits',
		'NilContext',
		'RemapBufferSize',
		'RootTableRedZone',
		'RootTableSize',
		'StartField',
		'StartObj',
		'Upward',
		'WeakRootTableSize',
		'WordMask'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices',
		'VMSqueakV3ObjectRepresentationConstants'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
ObjectMemory class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
]

{ #category : #accessing }
ObjectMemory class >> baseHeaderSize [
"To support SmartSyntaxPluginCodeGenerator"
	^BaseHeaderSize
]

{ #category : #'simulation only' }
ObjectMemory class >> characterObjectOf: characterCode [
	^(characterCode between: 0 and: 255) ifTrue:
		[characterCode asCharacter]
]

{ #category : #translation }
ObjectMemory class >> declareCVarsIn: aCCodeGenerator [
	self declareCAsOop:
			#(	memory endOfMemory memoryLimit
				youngStart youngStartLocal freeBlock
				compStart compEnd
				fwdTableNext fwdTableLast
				gcBiasToGrowThreshold )
		in: aCCodeGenerator.
	self declareCAsUSqLong:
			#( gcStartUsecs statFullGCUsecs statIncrGCUsecs statIGCDeltaUsecs )
		in: aCCodeGenerator.
	aCCodeGenerator
		var: #remapBuffer
		declareC: 'sqInt remapBuffer[RemapBufferSize + 1 /* ', (RemapBufferSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #rootTable
		declareC: 'sqInt rootTable[RootTableSize + 1 /* ', (RootTableSize + 1) printString, ' */]'.
	"Weak roots must be large enough for roots+remapBuffer+sizeof(allCallsOn: #markAndTrace:)"
	aCCodeGenerator
		var: #weakRoots
		declareC: 'sqInt weakRoots[WeakRootTableSize + 1 /* ', (WeakRootTableSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #headerTypeBytes
		declareC: 'sqInt headerTypeBytes[4]'.
	aCCodeGenerator
		var: #extraRoots
		declareC: 'sqInt* extraRoots[ExtraRootSize + 1 /* ', (ExtraRootSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #headerTypeBytes type: 'const sqInt' array: HeaderTypeExtraBytes
]

{ #category : #'api chacterization' }
ObjectMemory class >> hasSpurMemoryManagerAPI [
	^false
]

{ #category : #translation }
ObjectMemory class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #initialization }
ObjectMemory class >> initBytesPerWord: nBytes [

	BytesPerWord := nBytes.
	"N.B.  This is *not* output when generating the interpreter file.
	 It is left to the various sqConfig.h files to define correctly."
	VMBIGENDIAN := Smalltalk endianness == #big
]

{ #category : #'class initialization' }
ObjectMemory class >> initialize [
	"This is for Monticello package loading"
	self initializeWithOptions: Dictionary new
]

{ #category : #initialization }
ObjectMemory class >> initializeCompactClassIndices [
	"Initialize indices for compact classes we are going to depend on being compact.
	 The VI allows classes to become compact and become uncompact.  For efficiency
	 the VM assumes certain classes are compact with particular indices."

	"Smalltalk compactClassesArray"
	"{Array. LargePositiveInteger. Float. MethodContext. } collect: [:c| c -> c indexIfCompact]"

	ClassArrayCompactIndex := 3.
	ClassLargeNegativeIntegerCompactIndex := 4. "Was PseudoContext class"
	ClassLargePositiveIntegerCompactIndex := 5.
	ClassFloatCompactIndex := 6.
	ClassBlockClosureCompactIndex := 0 "12". "Prospective.  May still be TranslatedMethod class"
	ClassByteStringCompactIndex := 11.
	ClassBlockContextCompactIndex := 13.
	ClassMethodContextCompactIndex := 14.

	ClassByteArrayCompactIndex := 0.
	ClassMessageCompactIndex := 0.
	ClassBitmapCompactIndex := 0
]

{ #category : #initialization }
ObjectMemory class >> initializeObjectHeaderConstants [

	BytesPerWord ifNil: [BytesPerWord := 4].  "May get called on fileIn, so supply default"
	BaseHeaderSize := BytesPerWord.
	WordMask := (1 bitShift: BytesPerWord*8) - 1.
	
	"masks for type field"
	TypeMask := 3.
	AllButTypeMask := WordMask - TypeMask.

	"type field values"
	HeaderTypeSizeAndClass := 0.
	HeaderTypeClass := 1.
	HeaderTypeFree := 2.
	HeaderTypeShort := 3.
	HeaderTypeExtraBytes := { BytesPerWord * 2. BytesPerWord. 0. 0 }.

	"type field values used during the mark phase of GC"
	HeaderTypeGC := 2.
	GCTopMarker := 3.  "neither an oop, nor an oop+1, this value signals that we have crawled back up to the top of the marking phase."

	"Base header word bit fields"
	HashBits := 16r1FFE0000.
	HashBitsOffset := 17.
	HashMaskUnshifted := 16rFFF.
	self assert: (HashMaskUnshifted bitShift: HashBitsOffset) = HashBits.
	AllButHashBits := WordMask - HashBits.
	SizeMask := 16rFC.
	Size4Bit := 0.
BytesPerWord = 8 ifTrue:
		[SizeMask := 16rF8.  "Lose the 4 bit in temp 64-bit chunk format"
		Size4Bit := 4].  "But need it for ST size"
	"Note SizeMask + Size4Bit gives the mask needed for size fits of format word in classes.
		This is used in instantiateClass:indexableSize: "
	LongSizeMask := WordMask - 16rFF + SizeMask.
	LongSizeNumBits := 30. "30 bits of size info in long size filed."
	CompactClassMask := 16r1F000.

	"masks for root and mark bits"
	MarkBit := 1 bitShift: BytesPerWord*8 - 1.  "Top bit"
	RootBit := 1 bitShift: BytesPerWord*8 - 2.  "Next-to-Top bit"
	AllButMarkBit := WordMask - MarkBit.
	AllButRootBit := WordMask - RootBit.

	AllButMarkBitAndTypeMask := AllButTypeMask - MarkBit.

	ImmutabilityBit := 1 bitShift: BytesPerWord*8 - 3.  "Next-to-Next-To-Top bit"
	AllButImmutabilityBit := WordMask - ImmutabilityBit
]

{ #category : #initialization }
ObjectMemory class >> initializeSpecialObjectIndices [
	"Initialize indices into specialObjects array."

	NilObject := 0.
	FalseObject := 1.
	TrueObject := 2.
	SchedulerAssociation := 3.
	ClassBitmap := 4.
	ClassSmallInteger := 5.
	ClassByteString := ClassString := 6. "N.B.  Actually class ByteString"
	ClassArray := 7.
	"SmalltalkDictionary := 8."  "Do not delete!"
	ClassFloat := 9.
	ClassMethodContext := 10.
	ClassBlockContext := 11.
	ClassPoint := 12.
	ClassLargePositiveInteger := 13.
	TheDisplay := 14.
	ClassMessage := 15.
	"ClassCompiledMethod := 16. unused by the VM"
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
	"ClassProcess := 27. unused"
	CompactClasses := 28.
	TheTimerSemaphore := 29.
	TheInterruptSemaphore := 30.
	SelectorCannotInterpret := 34.
	"Was MethodContextProto := 35."
	ClassBlockClosure := 36.
	ClassFullBlockClosure := 37. "Was BlockContextProto := 37."
	ExternalObjectsArray := 38.
	ClassMutex := 39.
	"Was: ClassTranslatedMethod := 40."
	ProcessInExternalCodeTag := 40.
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
	"PrimErrTableIndex := 51. in VMClass class>>initializePrimitiveErrorCodes"
	ClassAlien := 52.
	SelectorInvokeCallback := 53.
	ClassUnsafeAlien := 54.

	ClassWeakFinalizer := 55.

	ForeignCallbackProcess := 56.

	SelectorUnknownBytecode := 57.
	SelectorCounterTripped := 58.
	SelectorSistaTrap := 59

]

{ #category : #initialization }
ObjectMemory class >> initializeWithOptions: optionsDictionary [
	"ObjectMemory initializeWithOptions: Dictionary new"

	self initBytesPerWord: (optionsDictionary at: #BytesPerWord ifAbsent: [4]).
	BytesPerOop := optionsDictionary at: #BytesPerOop ifAbsent: [BytesPerWord].

	"Translation flags (booleans that control code generation via conditional translation):"
	"generate assertion checks"
	DoAssertionChecks := optionsDictionary at: #DoAssertionChecks ifAbsent: [false].
	DoExpensiveAssertionChecks := optionsDictionary at: #DoExpensiveAssertionChecks ifAbsent: [false].

	self initializeObjectHeaderConstants. "Initializes BaseHeaderSize so do early"
	self initializeSpecialObjectIndices.
	self initializeCompactClassIndices.
	self initializePrimitiveErrorCodes.

	NilContext := 1.  "the oop for the integer 0; used to mark the end of context lists"

	RemapBufferSize := 25.
	RootTableSize := 2500.  	"number of root table entries (4 bytes/entry)"
	RootTableRedZone := RootTableSize - 100.	"red zone of root table - when reached we force IGC"
	WeakRootTableSize := RootTableSize + RemapBufferSize + 100.

	"tracer actions"
	StartField := 1.
	StartObj := 2.
	Upward := 3.
	Done := 4.

	ExtraRootSize := 2048. "max. # of external roots"
]

{ #category : #'simulation only' }
ObjectMemory class >> isImmediate: anObject [
	^anObject class == SmallInteger
]

{ #category : #translation }
ObjectMemory class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('self' 'interpreter' 'coInterpreter' 'heapMap') includes: aString
]

{ #category : #translation }
ObjectMemory class >> maxSmallInteger [
	^1073741823
]

{ #category : #accessing }
ObjectMemory class >> memoryManagerVersion [ 
	^ 'SqueakV3'
]

{ #category : #translation }
ObjectMemory class >> minSmallInteger [
	^-1073741824
]

{ #category : #translation }
ObjectMemory class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^false "used to be: ^'memory' = var"
]

{ #category : #accessing }
ObjectMemory class >> numSmallIntegerTagBits [
	^1
]

{ #category : #'accessing class hierarchy' }
ObjectMemory class >> objectRepresentationClass [
	^self subclassResponsibility
]

{ #category : #translation }
ObjectMemory class >> requiredMethodNames: options [
	"return the list of method names that should be retained for export or other support reasons"
	^self exportAPISelectors: options
]

{ #category : #accessing }
ObjectMemory class >> wordSize [
	"Answer the width of an object pointer, in bytes."

	^BytesPerWord
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
	How do we know that an object referenced by a weak class is being collected? Well,  this is based on two observations. First, objects will not change their relative locations in memory, meaning that if object A is created BEFORE object B it will always have a physical memory address which is LESS than B. Secondly, GC always works from a given starting address (youngStart during incremental GC; startOfMemory during fullGC) up to end of memory. If we can somehow guarantee that the weak reference is created after the object it points to we can easily implement the following simple scheme:
	1) Mark phase
		Do not trace the fields of any instances of weak classes.
	2) Sweep phase:
		a) Explicitly mark all free objects.
		b) 	If a weak reference is encountered check the the object it points to. 
			If the object is marked as free than we know that this weak reference's object is gone.
			Signal that it is gone.

	There is, however, one small problem with this approach. We cannot always guarantee that WeakReferences point backwards such as in the following piece of code:
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

	Note that a number of finalizations will only be executed during a fullGC. So, if you must guarantee that some object has been finalized you definitely need to do a fullGC.

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
	<var: #varLoc type: #'sqInt *'>
	extraRootCount >= ExtraRootSize ifTrue:[^false]. "out of space"
	extraRoots at: (extraRootCount := extraRootCount+1) put: varLoc.
	^true
]

{ #category : #'debug support' }
ObjectMemory >> addressCouldBeObj: address [
	<api>
	"Answer if address appears to be that of an object, which implies it is
	 safe to fetch the class and size. For code disassembly and assertions."
	^(address bitAnd: 3) = 0
	  and: [address asUnsignedInteger >= self startOfMemory
	  and: [address asUnsignedInteger < freeBlock
	  and: [(self headerType: address) ~= HeaderTypeGC]]]
]

{ #category : #'debug support' }
ObjectMemory >> addressCouldBeObjWhileForwarding: address [
	"Answer if address appears to be that of an object, which implies it is
	 safe to fetch the class and size. For code disassembly and assertions."
	^(address bitAnd: 3) = 0
	  and: [address asUnsignedInteger >= self startOfMemory
	  and: [address asUnsignedInteger < freeBlock]]
]

{ #category : #'debug support' }
ObjectMemory >> addressCouldBeOop: address [
	<api>
	"Answer if address appears to be that of either a SmallInteger or an object.
	 For code disassembly and assertions."
	^(self isIntegerObject: address)
	   or: [self addressCouldBeObj: address]
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
	fieldAddr := oop + (self lastPointerOf: oop).
	[self oop: fieldAddr isGreaterThan: oop] whileTrue:
		[fieldOop := self longAt: fieldAddr.
		 (self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldAddr put: fieldOop + offsetBytes].
		 fieldAddr := fieldAddr - self bytesPerOop].
	(self headerType: oop) ~= HeaderTypeShort ifTrue:
		["adjust class header if not a compact class"
		 classHeader := self longAt: oop - self wordSize.
		 newClassOop := (classHeader bitAnd: AllButTypeMask) + offsetBytes.
		 self longAt: oop - self wordSize put: (newClassOop bitOr: (classHeader bitAnd: TypeMask))]
]

{ #category : #'primitive support' }
ObjectMemory >> allInstancesOf: aClass [
	"Attempt to answer an array of all objects, excluding those that may
	 be garbage collected as a side effect of allocating the result array.
	 If no memory is available answer the number of instances as a SmallInteger.
	 Since objects are at least 16 bytes big, and the largest SmallInteger covers
	 1/4 of the address space, the count can never overflow."
	| count theClass resultArray newCount |
	"Count the currently accessible objects"
	count := 0.
	self allObjectsDo:
		[:obj|
		(self fetchClassOfNonImm: obj) = aClass ifTrue:
			[count := count + 1]].
	"Allocate result array, may cause GC"
	self pushRemappableOop: aClass.
	resultArray := self instantiateClass: self classArray indexableSize: count.
	theClass := self popRemappableOop.
	newCount := 0.
	self allObjectsDo:
		[:obj|
		 (self fetchClassOfNonImm: obj) = theClass ifTrue:
			[newCount := newCount + 1.
			 resultArray == nil ifFalse:
				[self storePointerUnchecked: newCount ofObject: resultArray withValue: obj]]].
	resultArray == nil ifTrue:
		[^self integerObjectOf: newCount].
	"If GC occurred during result array allocation, truncate unused portion of result array"
	newCount < count ifTrue:
		[self shorten: resultArray toIndexableSize: newCount].
	^resultArray
]

{ #category : #'primitive support' }
ObjectMemory >> allObjects [
	"Attempt to answer an array of all objects, excluding those that may
	 be garbage collected as a side effect of allocating the result array.
	 If no memory is available answer the number of objects as a SmallInteger.
	 Since objects are at least 4 bytes big, and the largest SmallInteger covers
	 1/4 of the address space, the count can never overflow."
	| count obj resultArray newCount |
	"Count the currently accessible objects"
	count := 0.
	self allObjectsDo:
		[:ign| count := count + 1].
	"Allocate result array, may cause GC"
	resultArray := self instantiateClass: self classArray indexableSize: count.
	"Store all objects in result array, excluding any reference to the result array itself,
	 as may happen if garbage collection occurred during allocation of the array. No store
	 check is necessary; the result array will be the last object in memory and hence new."
	newCount := 0.
	obj := self firstObject.
	[obj < resultArray] whileTrue:
		[(self isFreeObject: obj) ifFalse:
			[newCount := newCount + 1.
			 resultArray == nil ifFalse:
				[self storePointerUnchecked: newCount ofObject: resultArray withValue: obj]].
		 obj := self objectAfter: obj].
	resultArray == nil ifTrue:
		[^self integerObjectOf: count].
	"If GC occurred during result array allocation, truncate unused portion of result array"
	newCount < count ifTrue:
		[self shorten: resultArray toIndexableSize: newCount].
	^resultArray
]

{ #category : #'object enumeration' }
ObjectMemory >> allObjectsDo: aBlock [
	<inline: true>
	| oop |
	oop := self firstObject.
	[oop asUnsignedInteger < freeBlock] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[aBlock value: oop].
		 oop := self objectAfter: oop]
]

{ #category : #'object enumeration' }
ObjectMemory >> allObjectsDoSafely: aBlock [
	<inline: true>
	| oop |
	oop := self firstObject.
	[oop asUnsignedInteger < freeBlock] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[aBlock value: oop].
		 oop := self objectAfterWhileForwarding: oop]
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
		((self oop: (self longAt: array2 + fieldOffset) isLessThan: youngStart)
		 and: [self isNonIntegerObject: (self longAt: array2 + fieldOffset)])
			ifTrue: [^ false].
		fieldOffset := fieldOffset - self wordSize].
	^ true
]

{ #category : #allocation }
ObjectMemory >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format [
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes space for the base header word.) Initialize the header fields of the new object and fill the remainder of the object with a value appropriate for the format.
	May cause a GC"

	| newObj remappedClassOop |
	<inline: true>
	<var: #i type: 'usqInt'>
	<var: #end type: 'usqInt'>
	"remap classOop in case GC happens during allocation"
	hdrSize > 1 ifTrue: [self pushRemappableOop: classOop].
	newObj := self allocateChunk: byteSize + (hdrSize - 1 * self wordSize).
	hdrSize > 1 ifTrue: [remappedClassOop := self popRemappableOop].

	hdrSize = 3
		ifTrue: [self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + self wordSize put: (remappedClassOop bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + (self wordSize*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
			newObj := newObj + (self wordSize*2)].

	hdrSize = 2
		ifTrue: [self longAt: newObj put: (remappedClassOop bitOr: HeaderTypeClass).
			self longAt: newObj + self wordSize put: (baseHeader bitOr: HeaderTypeClass).
			newObj := newObj + self wordSize].

	hdrSize = 1
		ifTrue: [self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].
	"clear new object"
	doFill ifTrue:
		[| fillWord end i |
		 fillWord := format <= self lastPointerFormat
					ifTrue: [nilObj] "if pointers, fill with nil oop"
					ifFalse: [0].
		 end := newObj + byteSize.
		 i := newObj + self wordSize.
		 [i < end] whileTrue:
			[self longAt: i put: fillWord.
			 i := i + self wordSize]].
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

{ #category : #simulation }
ObjectMemory >> allocateMemoryOfSize: limit [
	<doNotGenerate>
	self setMemoryLimit: limit.
	memory := (self endianness == #little
					ifTrue: [LittleEndianBitmap]
					ifFalse: [Bitmap]) new: memoryLimit // 4
]

{ #category : #allocation }
ObjectMemory >> allocationUnit [
	^self wordSize
]

{ #category : #'interpreter access' }
ObjectMemory >> areIntegers: oop1 and: oop2 [
	"Test oop1 and oop2 to make sure both are SmallIntegers."
	^((oop1 bitAnd: oop2) bitAnd: 1) ~= 0
]

{ #category : #'header formats' }
ObjectMemory >> arrayFormat [
	<api>
	^2
]

{ #category : #allocation }
ObjectMemory >> attemptToShrink [
	"Attempt to shrink memory after successfully reclaiming lots of memory."
	| freeSizeNow |
	freeSizeNow := self freeSize.
	(freeSizeNow > shrinkThreshold
	 and: [freeSizeNow > growHeadroom]) ifTrue:
		[self shrinkObjectMemory: freeSizeNow - growHeadroom]
]

{ #category : #contexts }
ObjectMemory >> badContextSize: oop [
	| numSlots |
	numSlots := self numSlotsOf: oop.
	^numSlots ~= SmallContextSlots and: [numSlots ~= LargeContextSlots]
]

{ #category : #'header access' }
ObjectMemory >> baseHeader: oop [

	^ self longAt: oop
]

{ #category : #'header access' }
ObjectMemory >> baseHeader: oop put: aWord [

	^ self longAt: oop put: aWord
]

{ #category : #'interpreter access' }
ObjectMemory >> baseHeaderSize [
	"N.B. This would appear to hard-code the header size for 32-bit images.  But if generating
	 a 64-bit image, this method could be removed and the relevant one substituted.  We can't
	 mark this method as <doNotGenerate> as we need an actual method to guide code gen."
	^4
]

{ #category : #'garbage collection' }
ObjectMemory >> beRootIfOld: oop [ 
	"If this object is old, mark it as a root (because a new object 
	may be stored into it)"
	<api>
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
	<inline: false> "for debugging..."
	| header fwdBlock headerLoc |
	"If labelled, gcc duplicates the label when inlining updatePointersInRangeFrom:to:"
	header := self longAt: oop.
	(header bitAnd: MarkBit) ~= 0
		ifTrue: "This oop is forwarded"
			[fwdBlock := (header bitAnd: AllButMarkBitAndTypeMask) << 1.
			self assert: (self fwdBlockValid: fwdBlock).
			headerLoc := fwdBlock + self wordSize]
		ifFalse: "Normal -- no forwarding"
			[headerLoc := oop].
	"use headerLoc var to eliminate duplication on inlining noteAsRoot:headerLoc:
	 older versions of this method had two separate sends of noteAsRoot:headerLoc:"
	self noteAsRoot: oop headerLoc: headerLoc
]

{ #category : #become }
ObjectMemory >> become: array1 with: array2 [

	^ self become: array1 with: array2 twoWay: true copyHash: true

]

{ #category : #become }
ObjectMemory >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag [ 
	"All references to each object in array1 are swapped with all references to the corresponding
	 object in array2. That is, all pointers to one object are replaced with with pointers to the other.
	 The arguments must be arrays of the same length.  Ansswer if the operation succeeds."

	"Implementation: Uses forwarding blocks to update references as done in compaction."
	(self isArray: array1) ifFalse: [^false].
	(self isArray: array2) ifFalse: [^false].
	(self lastPointerOf: array1) = (self lastPointerOf: array2) ifFalse: [^false].
	(twoWayFlag or: [copyHashFlag])
		ifTrue: [(self containOnlyOops: array1 and: array2) ifFalse: [^false]]
		ifFalse: [(self containOnlyOops: array1) ifFalse: [^false]].

	(self prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag) ifFalse:
		[^false]. "fail; not enough space for forwarding table"

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
	growSize :=  growHeadroom*3/2 - (self sizeOfFree: freeBlock).
	self growObjectMemory: growSize
]

{ #category : #'garbage collection' }
ObjectMemory >> biasToGrowCheckGCLimit [
	| growth |
	growth := (youngStart - self startOfMemory) - gcBiasToGrowThreshold.
	growth < 0 ifTrue: [gcBiasToGrowThreshold := youngStart - memory].
	growth > gcBiasToGrowGCLimit
		 ifTrue: 
			[self fullGC.
			gcBiasToGrowThreshold := youngStart - memory].

					
]

{ #category : #'interpreter access' }
ObjectMemory >> booleanObjectOf: bool [
	<inline: true>
	^bool ifTrue: [trueObj] ifFalse: [falseObj]
]

{ #category : #accessing }
ObjectMemory >> bootstrapping [
	^false
]

{ #category : #'header access' }
ObjectMemory >> byteFormatForNumBytes: numBytes [
	^self firstByteFormat + (4 - numBytes bitAnd: 3)
]

{ #category : #'header access' }
ObjectMemory >> byteFormatMask [
	^16rC
]

{ #category : #'object access' }
ObjectMemory >> byteSizeOf: oop [
	<api>
	(self isIntegerObject: oop) ifTrue:[^0].
	^self numBytesOf: oop
]

{ #category : #'image segment in/out' }
ObjectMemory >> byteSwapByteObjectsFrom: startOop to: stopAddr flipFloatsIf: flipFloatWords [
	"Byte-swap the words of all bytes objects in a range of the 
	image, including Strings, ByteArrays, and CompiledMethods. 
	This returns these objects to their original byte ordering 
	after blindly byte-swapping the entire image. For compiled 
	methods, byte-swap only their bytecodes part.  For Floats
	swap their most and least significant words if required."
	| oop fmt temp wordAddr |
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[fmt := self formatOf: oop.
			fmt >= self firstByteFormat ifTrue:
				["oop contains bytes; unswap"
				wordAddr := oop + self baseHeaderSize.
				fmt >= self firstCompiledMethodFormat ifTrue: "compiled method; start after methodHeader and literals"
					[wordAddr := wordAddr + ((self literalCountOf: oop) + LiteralStart * self bytesPerOop)].
				self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
			fmt = self firstLongFormat  ifTrue: "Bitmap, Float etc"
				[(self compactClassIndexOf: oop) = ClassFloatCompactIndex
					ifTrue:
						[flipFloatWords ifTrue:
							[temp := self longAt: oop + self baseHeaderSize.
							 self longAt: oop + self baseHeaderSize put: (self longAt: oop + self baseHeaderSize + 4).
							 self longAt: oop + self baseHeaderSize + 4 put: temp]]
					ifFalse:
						[self wordSize = 8 ifTrue:
							["Object contains 32-bit half-words packed into 64-bit machine words."
							wordAddr := oop + self baseHeaderSize.
							self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]]]].
			oop := self objectAfter: oop]
]

{ #category : #'memory access' }
ObjectMemory >> byteSwapped32IfBigEndian: w [
	"If the VM is big endian, then swap the bytes of w"
	<api>
	<var: 'w' type: #'unsigned int'>
	<returnTypeC: #'unsigned int'>
	self cppIf: VMBIGENDIAN
		ifTrue: [^w byteSwap32]
		ifFalse: [^w bitAnd: 16rFFFFFFFF]
]

{ #category : #'memory access' }
ObjectMemory >> byteSwapped64IfBigEndian: w [
	"If the VM is big endian, then swap the bytes of w"
	<api>
	<var: 'w' type: #'unsigned long long'>
	<returnTypeC: #'unsigned long long'>
	self cppIf: VMBIGENDIAN
		ifTrue: [^w byteSwap64]
		ifFalse: [^w bitAnd: 16rFFFFFFFFFFFFFFFF]
]

{ #category : #'image save/restore' }
ObjectMemory >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."
	<api>
	<returnTypeC: #sqInt>
	^self cppIf: self wordSize = 4
		ifTrue: [w byteSwap32]
		ifFalse: [w byteSwap64]
]

{ #category : #allocation }
ObjectMemory >> bytesLeft: includingSwap [
	^(self sizeOfFree: freeBlock) "already commited"
		+ (self sqMemoryExtraBytesLeft: includingSwap).
]

{ #category : #accessing }
ObjectMemory >> bytesPerOop [
	"N.B. This would appear to hard-code the header size for 32-bit images.  But if generating
	 a 64-bit image, this method could be removed and the relevant one substituted.  We can't
	 mark this method as <doNotGenerate> as we need an actual method to guide code gen."
	^4
]

{ #category : #'simulation support' }
ObjectMemory >> cCoerceSimple: value to: cTypeString [
	<doNotGenerate>
	^cTypeString caseOf:
	   {	[#'char *']			->	[value].
		[#'unsigned int']	->	[value]. }
]

{ #category : #'interpreter access' }
ObjectMemory >> changeClassOf: rcvr to: argClass [
	"Attempt to change the class of the receiver to the argument given that the
	 format of the receiver matches the format of the argument.  If successful,
	 answer 0, otherwise answer an error code indicating the reason for failure. 
	 Fail if the receiver is an instance of a compact class and the argument isn't,
	 or if the format of the receiver is incompatible with the format of the argument,
	 or if the argument is a fixed class and the receiver's size differs from the size
	 that an instance of the argument should have."
	| classHdr sizeHiBits argClassInstByteSize argFormat rcvrFormat rcvrHdr ccIndex |
	"Check what the format of the class says"
	classHdr := self formatOfClass: argClass. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits := (classHdr bitAnd: 16r60000) >> 9.
	classHdr := classHdr bitAnd: 16r1FFFF.
	argClassInstByteSize := (classHdr bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"

	"Check the receiver's format against that of the class"
	argFormat := self formatOfHeader: classHdr.
	rcvrHdr := self baseHeader: rcvr.
	rcvrFormat := self formatOfHeader: rcvrHdr.
	"If the receiver is a byte object we need to clear the number of odd bytes from the format."
	rcvrFormat > self firstByteFormat ifTrue:
		[rcvrFormat := rcvrFormat bitAnd: 16rC].
	argFormat = rcvrFormat ifFalse:
		[^PrimErrInappropriate]. "no way"

	"For fixed field classes, the sizes must match.
	Note: argClassInstByteSize-4 because base header is included in class size."
	argFormat < self arrayFormat
		ifTrue:
			[(argClassInstByteSize - self baseHeaderSize) ~= (self numBytesOf: rcvr) ifTrue:
				[^PrimErrBadReceiver]]
		ifFalse:
			[argFormat = self indexablePointersFormat ifTrue: "For indexable plus fixed fields the receiver must be at least big enough."
				[(argClassInstByteSize - self baseHeaderSize) > (self numBytesOf: rcvr) ifTrue:
					[^PrimErrBadReceiver]]].

	(self headerTypeOfHeader: rcvrHdr) = HeaderTypeShort
		ifTrue: "Compact classes. Check if the arg's class is compact and exchange ccIndex"
			[ccIndex := classHdr bitAnd: CompactClassMask.
			ccIndex = 0 ifTrue:
				[^PrimErrInappropriate]. "class is not compact"
			self cppIf: IMMUTABILITY
				ifTrue: [(rcvrHdr bitAnd: ImmutabilityBit) ~= 0 ifTrue:
							[^PrimErrNoModification]].
			self baseHeader: rcvr put: ((rcvrHdr bitClear: CompactClassMask) bitOr: ccIndex)]
		ifFalse: "Exchange the class pointer, which could make rcvr a root for argClass"
			[self cppIf: IMMUTABILITY
				ifTrue: [(rcvrHdr bitAnd: ImmutabilityBit) ~= 0 ifTrue:
							[^PrimErrNoModification]].
			"N.B. the recursive scan-mark algorithm uses the header word's size and compact class
			 fields to determine the header type when it reuses the header type bits for the mark
			 state.  So it is alas an invariant that non-compact headers have a 0 compact class field."
			(self compactClassIndexOfHeader: rcvrHdr) ~= 0 ifTrue:
				[self baseHeader: rcvr put: (rcvrHdr bitClear: CompactClassMask)].			
			self longAt: rcvr - self baseHeaderSize put: (argClass bitOr: (self headerTypeOfHeader: rcvrHdr)).
			(self oop: rcvr isLessThan: youngStart) ifTrue:
				[self possibleRootStoreInto: rcvr value: argClass]].
	"ok"
	^0
]

{ #category : #'object access' }
ObjectMemory >> characterObjectOf: characterCode [
	<api>
	^(characterCode between: 0 and: 255)
		ifTrue: [self fetchPointer: characterCode ofObject: self characterTable]
		ifFalse: [nilObj]
]

{ #category : #'plugin support' }
ObjectMemory >> characterTable [
	<api>
	^self splObj: CharacterTable
]

{ #category : #'plugin support' }
ObjectMemory >> cheapIsInMemory: address [ 
	"Answer if the given address is in ST object memory.  For simulation only."
	<doNotGenerate>
	^address >= self startOfMemory
	  and: [address < endOfMemory]
]

{ #category : #'memory access' }
ObjectMemory >> checkAddress: byteAddress [ 
	"Keep this method around for debugging the C code."
	(self oop: byteAddress isLessThan: self startOfMemory)
		ifTrue: [self error: 'bad address: negative'].
	(self oop: byteAddress isGreaterThanOrEqualTo: memoryLimit)
		ifTrue: [self error: 'bad address: past end of heap']
]

{ #category : #initialization }
ObjectMemory >> checkCompactIndex: compactIndex isClass: specialIndex named: name [
	"Check that a class the VM assumes is compact has the right index."
	<inline: true> "macrofication of the name arg in invalidCompactClassError only works if this method is inlined so the name is a string literal not a parameter"
	(compactIndex ~= 0
	 and: [(self splObj: specialIndex) ~= (self compactClassAt: compactIndex)]) ifTrue:
		[self invalidCompactClassError: name]
]

{ #category : #'memory access' }
ObjectMemory >> checkHeapIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Scan all objects in the heap checking that every
	 pointer points to a header.  Scan the rootTable, remapBuffer and
	 extraRootTable checking that every entry is a pointer to a header.
	 Check that the number of roots is correct and that all rootTable
	 entries have their rootBit set. Answer if all checks pass."
	| ok obj sz hdr fmt fi fieldOop numRootsInHeap |
	<inline: false>
	ok := true.
	numRootsInHeap := 0.
	obj := self firstObject.
	[self oop: obj isLessThan: self startOfFreeSpace] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[hdr := self baseHeader: obj.
				 (self isYoungRootHeader: hdr) ifTrue:
					[numRootsInHeap := numRootsInHeap + 1].
				 (self compactClassIndexOfHeader: hdr) = 0 ifTrue:
					[fieldOop := (self classHeader: obj) bitAnd: AllButTypeMask.
					 ((self isIntegerObject: fieldOop)
					   or: [(self heapMapAtWord: (self pointerForOop: fieldOop)) = 0]) ifTrue:
						[self print: 'object leak in '; printHex: obj; print: ' class = '; printHex: fieldOop; cr.
						 ok := false]].
				 fmt := self formatOfHeader: hdr.
				 (fmt <= self lastPointerFormat or: [fmt >= self firstCompiledMethodFormat]) ifTrue:
					[fmt >= self firstCompiledMethodFormat
						ifTrue: [fi := (self literalCountOf: obj) + LiteralStart]
						ifFalse: [(fmt = self indexablePointersFormat and: [self isContextHeader: hdr])
									ifTrue: [fi := CtxtTempFrameStart + (self fetchStackPointerOf: obj)]
									ifFalse: [fi := self lengthOf: obj]].
					[(fi := fi - 1) >= 0] whileTrue:
						[fieldOop := self fetchPointer: fi ofObject: obj.
						 (self isNonIntegerObject: fieldOop) ifTrue:
							[(fieldOop bitAnd: self wordSize - 1) ~= 0
								ifTrue:
									[self print: 'misaligned oop in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
									 ok := false]
								ifFalse:
									[(self heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
										[self print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
										 ok := false]]]]].
				 sz := self sizeBitsOf: obj].
		 obj := self oopFromChunk: obj + sz].
	numRootsInHeap ~= rootTableCount ifTrue:
		[self print: 'root count mismatch. #heap roots '; printNum: numRootsInHeap; print: '; #roots '; printNum: rootTableCount; cr.
		"But the system copes with overflow..."
		ok := rootTableOverflowed and: [allocationCount > allocationsBetweenGCs]].
	1 to: rootTableCount do:
		[:ri|
		obj := rootTable at: ri.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[self print: 'misaligned oop in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
				 ok := false]
			ifFalse:
				[(self heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[self print: 'object leak in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
						 ok := false]
					ifFalse:
						[hdr := self baseHeader: obj.
						 (self isYoungRootHeader: hdr) ifFalse:
							[self print: 'non-root in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
							 ok := false]]]].
	1 to: remapBufferCount do:
		[:ri|
		obj := remapBuffer at: ri.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[self print: 'misaligned remapRoot @ '; printNum: ri; print: ' = '; printHex: obj; cr.
				 ok := false]
			ifFalse:
				[(self heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[self print: 'object leak in remapRoots @ '; printNum: ri; print: ' = '; printHex: obj; cr.
						 ok := false]]].
	1 to: extraRootCount do:
		[:ri|
		obj := (extraRoots at: ri) at: 0.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[self print: 'misaligned extraRoot @ '; printNum: ri; print: ' => '; printHex: obj; cr.
				 ok := false]
			ifFalse:
				[(self heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[self print: 'object leak in extraRoots @ '; printNum: ri; print: ' => '; printHex: obj; cr.
						 ok := false]]].
	^ok
]

{ #category : #'debug support' }
ObjectMemory >> checkOkayOop: oop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class.
	 Answer true if OK.  Otherwise print reason and answer false."

	<api>
	<var: #oop type: #usqInt>
	| sz type fmt unusedBit |

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(oop >= self startOfMemory and: [oop < endOfMemory])
		ifFalse: [ self print: 'oop is not a valid address'; cr. ^false ].
	((oop \\ self wordSize) = 0)
		ifFalse: [ self print: 'oop is not a word-aligned address'; cr. ^false ].
	sz := self sizeBitsOf: oop.
	(oop + sz) < endOfMemory
		ifFalse: [ self print: 'oop size would make it extend beyond the end of memory'; cr. ^false ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self print: 'oop is a free chunk, not an object'; cr. ^false ].
	type = HeaderTypeShort ifTrue: [
		(self compactClassIndexOf: oop) = 0
			ifTrue:  [ self print: 'cannot have zero compact class field in a short header'; cr. ^false ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= self wordSize) and: [(self headerType: oop - self wordSize) = type])
			ifFalse: [ self print: 'class header word has wrong type'; cr. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (self wordSize*2)) and:
		 [(self headerType: oop - (self wordSize*2)) = type and:
		 [(self headerType: oop - self wordSize) = type]])
			ifFalse: [ self print: 'class header word has wrong type'; cr. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self print: 'oop has an unknown format type'; cr. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	self wordSize = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self print: 'unused header bit 30 is set; should be zero'; cr. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self print: 'mark bit should not be set except during GC' ].
xxx"
	((self isYoungRoot: oop) and: [oop >= youngStart])
		ifTrue: [ self print: 'root bit is set in a young object'; cr. ^false ].
	^true

]

{ #category : #'debug support' }
ObjectMemory >> checkOkayYoungReferrer: obj [
	"Verify that the given obj is a valid youngReferrer. Check RootBit is set and
	 is in rootTable.  Answer true if OK.  Otherwise print reason and answer false.
	 Assumes the object contains young references."

	(self oop: obj isGreaterThanOrEqualTo: youngStart) ifTrue:
		[^true].

	(self isYoungRoot: obj) ifFalse:
		[ self print: 'root bit is not set in '; printHex: obj; cr. ^false ].

	1 to: rootTableCount do:
		[:i| obj = (rootTable at: i) ifTrue: [^true]].

	self printHex: obj; print: ' has root bit set but is not in rootTable'; cr.

	^false

]

{ #category : #'debug support' }
ObjectMemory >> checkOopHasOkayClass: obj [
	"Attempt to verify that the given obj has a reasonable behavior. The class must be a
	 valid, non-integer oop and must not be nilObj. It must be a pointers object with three
	 or more fields. Finally, the instance specification field of the behavior must match that
	 of the instance. If OK answer true.  If  not, print reason and answer false."

	<api>
	<var: #obj type: #usqInt>
	| objClass formatMask behaviorFormatBits objFormatBits |
	<var: #objClass type: #usqInt>

	(self checkOkayOop: obj) ifFalse:
		[^false].
	objClass := self cCoerce: (self fetchClassOfNonImm: obj) to: #usqInt.

	(self isIntegerObject: objClass) ifTrue:
		[self print: 'obj '; printHex: obj; print: ' a SmallInteger is not a valid class or behavior'; cr. ^false].
	(self okayOop: objClass) ifFalse:
		[self print: 'obj '; printHex: obj; print: ' class obj is not ok'; cr. ^false].
	((self isPointersNonImm: objClass) and: [(self lengthOf: objClass) >= 3]) ifFalse:
		[self print: 'obj '; printHex: obj; print: ' a class (behavior) must be a pointers object of size >= 3'; cr. ^false].
	formatMask := (self isBytes: obj)
						ifTrue: [16rC00]  "ignore extra bytes size bits"
						ifFalse: [16rF00].

	behaviorFormatBits := (self formatOfClass: objClass) bitAnd: formatMask.
	objFormatBits := (self baseHeader: obj) bitAnd: formatMask.
	behaviorFormatBits = objFormatBits ifFalse:
		[self print: 'obj '; printHex: obj; print: ' and its class (behavior) formats differ'; cr. ^false].
	^true
]

{ #category : #'debug support' }
ObjectMemory >> checkOopIntegrity: obj named: name [
	<inline: false>
	<var: #name type: #'char *'>
	(self heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
		[^true].
	self print: name; print: ' leak '; printHex: obj; cr.
	^false
]

{ #category : #'debug support' }
ObjectMemory >> checkOopIntegrity: obj named: name index: i [
	<inline: false>
	<var: #name type: #'char *'>
	(self heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
		[^true].
	self print: name; print: ' leak @ '; printNum: i; print: ' = '; printHex: obj; cr.
	^false
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
	<api>
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
	<api>
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
	<api>
	^self splObj: ClassFloat
]

{ #category : #'header access' }
ObjectMemory >> classHeader: oop [
	<api>
	^self longAt: oop - self baseHeaderSize
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
ObjectMemory >> classMutex [
	^self splObj: ClassMutex
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
	<api>
	^self splObj: ClassSmallInteger
]

{ #category : #'plugin support' }
ObjectMemory >> classString [
	^self splObj: ClassByteString
]

{ #category : #'plugin support' }
ObjectMemory >> classUnsafeAlien [
	^self splObj: ClassUnsafeAlien
]

{ #category : #'debug support' }
ObjectMemory >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header."
	| oop |
	<inline: false>
	self clearHeapMap.
	oop := self firstObject.
	[oop = nil] whileFalse:
		[self heapMapAtWord: (self pointerForOop: oop) Put: 1.
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'garbage collection' }
ObjectMemory >> clearRootsTable [
	"Clear the root bits of the current roots, then empty the roots table. "
	"Caution: This should only be done when the young object space is empty."
	"reset the roots table (after this, all objects are old so there are no roots)"
	1 to: rootTableCount do:
		[:i | | oop |
		oop := rootTable at: i.
		self longAt: oop put: ((self longAt: oop) bitAnd: AllButRootBit).
		rootTable at: i put: 0].
	rootTableCount := 0.
	rootTableOverflowed := false.
]

{ #category : #allocation }
ObjectMemory >> clone: obj [
	"Return a shallow copy of the given object. May cause GC"
	"Assume: Oop is a real object, not a small integer."

	| extraHdrBytes bytes newChunk remappedOop fromIndex toIndex lastFrom newOop header hash |
	<inline: false>
	<var: #lastFrom type: #usqInt>
	<var: #fromIndex type: #usqInt>
	self assert: (self isNonIntegerObject: obj).
	extraHdrBytes := self extraHeaderBytes: obj.
	bytes := self sizeBitsOf: obj.
	bytes := bytes + extraHdrBytes.

	"allocate space for the copy, remapping obj in case of a GC"
	self pushRemappableOop: obj.
	"check it is safe to allocate this much memory. Return 0 if not"
	(self sufficientSpaceToAllocate: 2500 + bytes) ifFalse:[^0].
	newChunk := self allocateChunk: bytes.
	remappedOop := self popRemappableOop.

	"copy old to new including all header words"
	toIndex := newChunk - self wordSize.  "loop below uses pre-increment"
	fromIndex := (remappedOop - extraHdrBytes) - self wordSize.
	lastFrom := fromIndex + bytes.
	[fromIndex < lastFrom] whileTrue:
		[self longAt: (toIndex := toIndex + self wordSize) put: (self longAt: (fromIndex := fromIndex + self wordSize))].
	newOop := newChunk + extraHdrBytes.  "convert from chunk to oop"

	"fix base header: compute new hash and clear Mark and Root bits"
	hash := self newObjectHash.
	header := (self longAt: newOop) bitAnd: 16r1FFFF.
	"use old ccIndex, format, size, and header-type fields"
	header := header bitOr: ((hash << HashBitsOffset) bitAnd: HashBits).
	self longAt: newOop put: header.
	^newOop

]

{ #category : #'interpreter access' }
ObjectMemory >> compactClassAt: ccIndex [
	"Index must be between 1 and compactClassArray size.  A zero compact class
	 index in the base header indicates that the class is in the class header word."
	<api>
	<inline: true>
	^self fetchPointer: ccIndex - 1 ofObject: (self splObj: CompactClasses)
]

{ #category : #'cog jit support' }
ObjectMemory >> compactClassFieldLSB [
	<api>
	<cmacro>
	^12
]

{ #category : #'object access' }
ObjectMemory >> compactClassIndexOf: oop [
	<api>
	<inline: true>
	^((self baseHeader: oop) >> self compactClassFieldLSB) bitAnd: 16r1F
]

{ #category : #'object format' }
ObjectMemory >> compactClassIndexOfClass: classObj [
	<api>
	^self compactClassIndexOfHeader: (self formatOfClass: classObj)
]

{ #category : #'header access' }
ObjectMemory >> compactClassIndexOfHeader: header [
	<api>
	<inline: true>
	^(header >> self compactClassFieldLSB) bitAnd: 16r1F
]

{ #category : #initialization }
ObjectMemory >> compactIndexOfClass: aClassOop [
	"Check that a class the VM assumes is compact has the right index."
	| cct |
	cct := self splObj: CompactClasses.
	(self lengthOf: cct) - 1 to: 0 by: -2 do:
		[:index|
		(self fetchPointer: index ofObject: cct) = aClassOop ifTrue:
			[^index + 1]].
	^0
]

{ #category : #become }
ObjectMemory >> containOnlyMutableOops: array1 and: array2 [ 
	"Return true if neither array contains an immutable.
	 You may not be allowed to become: immutables."
	| fieldOffset |
	fieldOffset := self lastPointerOf: array1.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[(self isOopImmutable: (self longAt: array1 + fieldOffset)) ifTrue: [^false].
		 (self isOopImmutable: (self longAt: array2 + fieldOffset)) ifTrue: [^false].
		 fieldOffset := fieldOffset - self wordSize].
	^true
]

{ #category : #become }
ObjectMemory >> containOnlyOops: array [
	"Answer if the array does not contain a small integer. You 
	  can't become: SmallIntegers!"
	| fieldOffset |
	fieldOffset := self lastPointerOf: array.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[(self isIntegerObject: (self longAt: array + fieldOffset)) ifTrue: [^ false].
		 fieldOffset := fieldOffset - self bytesPerOop].
	^true
]

{ #category : #become }
ObjectMemory >> containOnlyOops: array1 and: array2 [ 
	"Answer if neither array contains a small integer. You 
	can't become: integers!"
	| fieldOffset |
	fieldOffset := self lastPointerOf: array1.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize]
		whileTrue: [(self isIntegerObject: (self longAt: array1 + fieldOffset)) ifTrue: [^ false].
			(self isIntegerObject: (self longAt: array2 + fieldOffset)) ifTrue: [^ false].
			fieldOffset := fieldOffset - self bytesPerOop].
	^ true
]

{ #category : #'image segment in/out' }
ObjectMemory >> copyObj: oop toSegment: segmentWordArray addr: lastSeg stopAt: stopAddr saveOopAt: oopPtr headerAt: hdrPtr [
	"Copy this object into the segment beginning at lastSeg.
	Install a forwarding pointer, and save oop and header.
	Fail if out of space.  Return the next segmentAddr if successful."

	"Copy the object..."
	| extraSize bodySize hdrAddr |
	<inline: false>
	self flag: #Dan.  "None of the imageSegment stuff has been updated for 64 bits"
	extraSize := self extraHeaderBytes: oop.
	bodySize := self sizeBitsOf: oop.
	(self oop: (lastSeg + extraSize + bodySize) isGreaterThanOrEqualTo: stopAddr) ifTrue:
		[^0]. "failure"
	self transfer: extraSize + bodySize // self wordSize  "wordCount"
		from: oop - extraSize
		to: lastSeg+self wordSize.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr := lastSeg+self wordSize + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: AllButRootBit - MarkBit).

	self forward: oop to: (lastSeg+self wordSize + extraSize - segmentWordArray)
		savingOopAt: oopPtr
		andHeaderAt: hdrPtr.

	"Return new end of segment"
	^lastSeg + extraSize + bodySize
]

{ #category : #'interpreter access' }
ObjectMemory >> dbgFloatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or if it is not, answer 0."

	| isFloat result |
	<returnTypeC: #double>
	<var: #result type: #double>
	isFloat := self isFloatInstance: oop.
	isFloat ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + self baseHeaderSize into: result.
		 ^result].
	^0.0
]

{ #category : #'plugin support' }
ObjectMemory >> displayObject [
	^self splObj: TheDisplay
]

{ #category : #accessing }
ObjectMemory >> endOfMemory [
	^endOfMemory
]

{ #category : #'header access' }
ObjectMemory >> ensureBehaviorHash: oop [

	^self hashBitsOf: oop
]

{ #category : #'forward compatibility' }
ObjectMemory >> ensureSemaphoreUnforwardedThroughContext: aSemaphore [
	"Compatibility with SpurMemoryManager"
	<inline: true>
]

{ #category : #'gc -- compaction' }
ObjectMemory >> existImmutableReferencesToForwardedInRangeFrom: memStart to: memEnd [
	"Answer if any immutable objects refer to any forwarded objects so that the become: primitives can fail if a become would update a reference from an immutable object."

	| oop |
	1 to: rootTableCount do:
		[:i | 
		oop := rootTable at: i.
		(oop < memStart or: [oop >= memEnd]) ifTrue:
			["Note: must not remap the fields of any object twice!"
			"remap this oop only if not in the memory range 
			covered below"
			(self objectIsImmutableAndReferencesForwarded: oop) ifTrue:
				[^true]]].

	oop := self oopFromChunk: memStart.
	[oop < memEnd] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[(self objectIsImmutableAndReferencesForwarded: oop) ifTrue:
				[^true]].
		oop := self objectAfterWhileForwarding: oop].
	^false
]

{ #category : #'oop/chunk conversion' }
ObjectMemory >> extraHeaderBytes: oopOrChunk [
	"Return the number of extra bytes used by the given object's header."
	"Warning: This method should not be used during marking, when the header type bits of an object may be incorrect."

	"JMM should be an array lookup!" 
	<inline: true>
	^ headerTypeBytes at: (self headerType: oopOrChunk).
]

{ #category : #'plugin support' }
ObjectMemory >> falseObject [
	<api>
	^falseObj
]

{ #category : #'object access' }
ObjectMemory >> fetchByte: byteIndex ofObject: oop [
	<api>
	^self byteAt: oop + self baseHeaderSize + byteIndex
]

{ #category : #'object access' }
ObjectMemory >> fetchClassOf: oop [ 
	| ccIndex |
	<inline: true>
	^(self isIntegerObject: oop)
		ifTrue: [self splObj: ClassSmallInteger]
		ifFalse:
			[(ccIndex := (self compactClassIndexOf: oop)) = 0
				ifTrue: [(self classHeader: oop) bitAnd: AllButTypeMask]
				ifFalse: [self compactClassAt: ccIndex]]
]

{ #category : #'object access' }
ObjectMemory >> fetchClassOfNonImm: oop [ 
	| ccIndex |
	<inline: true>
	^(ccIndex := (self compactClassIndexOf: oop)) = 0
		ifTrue: [(self classHeader: oop) bitAnd: AllButTypeMask]
		ifFalse: [self compactClassAt: ccIndex]
]

{ #category : #'object access' }
ObjectMemory >> fetchLong32: fieldIndex ofFloatObject: oop [
	"index by word size, and return a pointer as long as the word size"
	<inline: true>
	^self fetchLong32: fieldIndex ofObject: oop
]

{ #category : #'object access' }
ObjectMemory >> fetchLong32: fieldIndex ofObject: oop [
	" index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^ self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
]

{ #category : #'object access' }
ObjectMemory >> fetchLong64: longIndex ofObject: oop [
	<returnTypeC: #sqLong>
	^self cppIf: BytesPerWord = 8
		ifTrue: [self long64At: oop + self baseHeaderSize + (longIndex << 3)]
		ifFalse:
			["BEWARE OF SIGN EXTENSION ON LEAST SIGNIFICAND LIMB
			'unsigned int) CAST IS THERE TO PREVENT SUCH ERROR"
			self cppIf: VMBIGENDIAN
				ifTrue: [((self long32At: oop + self baseHeaderSize + (longIndex << 3)) asUnsignedLongLong << 32)
					+ (self cCoerceSimple: (self long32At: oop + self baseHeaderSize + (longIndex << 3 + 4)) to: #'unsigned int')]
				ifFalse: [(self cCoerceSimple: (self long32At: oop + self baseHeaderSize + (longIndex << 3)) to: #'unsigned int')
					+ ((self long32At: oop + self baseHeaderSize + (longIndex << 3 + 4)) asUnsignedLongLong << 32)]]
]

{ #category : #'object access' }
ObjectMemory >> fetchPointer: fieldIndex ofObject: oop [
	"index by word size, and return a pointer as long as the word size"
	<api>
	^self longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
ObjectMemory >> fetchShort16: shortIndex ofObject: oop [
	^self shortAt: oop + self baseHeaderSize + (shortIndex << 1)
]

{ #category : #finalization }
ObjectMemory >> finalizeReference: oop [ 
	"During sweep phase we have encountered a weak reference. Check if its object
	 has gone away (or is about to) and if so, signal a semaphore.  Do *not* inline
	 this in sweepPhase - it is quite an unlikely case to run into a weak reference"
	| weakOop oopGone chunk numFields firstField lastField |
	<inline: false>
	<var: #oop type: #usqInt>
	<var: #weakOop type: #usqInt>
	numFields := self nonWeakFieldsOf: oop. "so nonWeakFieldsOf: may be inlined"
	firstField := self baseHeaderSize + (numFields << self shiftForWord).
	lastField := self lastPointerOf: oop.
	firstField to: lastField by: self wordSize do:
		[:i|
		weakOop := self longAt: oop + i.
		"ar 1/18/2005: Added oop < youngStart test to make sure we're not testing
		objects in non-GCable region. This could lead to a forward reference in
		old space with the oop pointed to not being marked and thus treated as free."
		(weakOop = nilObj or: [(self isIntegerObject: weakOop) or:[weakOop < youngStart]]) ifFalse:
			["Check if the object is being collected. 
			If the weak reference points  
			* backward: check if the weakOops chunk is free
			* forward: check if the weakOoop has been marked by GC"
			weakOop < oop
				ifTrue: [chunk := self chunkFromOop: weakOop.
						oopGone := ((self longAt: chunk) bitAnd: TypeMask) = HeaderTypeFree]
				ifFalse: [oopGone := (self isMarked: weakOop) not].
			oopGone ifTrue: "Store nil in the pointer and signal the  interpreter"
				[self longAt: oop + i put: nilObj.
				self 
					cppIf: PharoVM 
					ifTrue: [ numFields >= 2 ifTrue: [ self weakFinalizerCheck: oop ] ].
				self signalFinalization: oop]]]
]

{ #category : #'object enumeration' }
ObjectMemory >> firstAccessibleObject [
	"Return the first accessible object in the heap."
	| obj |
	obj := self firstObject.
	[self oop: obj isLessThan: endOfMemory] whileTrue:
		[(self isFreeObject: obj) ifFalse: [^obj].
		 obj := self objectAfter: obj].
	self error: 'heap is empty'.
	^nil
]

{ #category : #'header formats' }
ObjectMemory >> firstByteFormat [
	<api>
	<cmacro>
	^8
]

{ #category : #'header formats' }
ObjectMemory >> firstCompiledMethodFormat [
	<api>
	<cmacro>
	^12
]

{ #category : #'object access' }
ObjectMemory >> firstFixedField: oop [

	<returnTypeC: #'void *'>
	^ self pointerForOop: oop + self baseHeaderSize
]

{ #category : #'debug support' }
ObjectMemory >> firstFixedFieldOfMaybeImmediate: oop [
	"for the message send breakpoint; selectors can be immediates."
	<inline: false>
	^(self isImmediate: oop)
		ifTrue: [oop asVoidPointer]
		ifFalse: [self firstFixedField: oop]
]

{ #category : #'object format' }
ObjectMemory >> firstIndexableField: oop [
	"NOTE: overridden in various simulator subclasses to add coercion to CArray, so please duplicate any changes"
	| hdr fmt totalLength fixedFields |
	<returnTypeC: #'void *'>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	fmt <= self lastPointerFormat ifTrue:
		["pointer; may need to delve into the class format word"
		totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
		fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
		^self pointerForOop: oop + self baseHeaderSize + (fixedFields << self shiftForWord)].
	^self pointerForOop: oop + self baseHeaderSize
]

{ #category : #'header formats' }
ObjectMemory >> firstLongFormat [
	<api>
	<cmacro>
	^6
]

{ #category : #'object enumeration' }
ObjectMemory >> firstObject [
	"Return the first object or free chunk in the heap."

	^ self oopFromChunk: self startOfMemory
]

{ #category : #'image save/restore' }
ObjectMemory >> firstSegmentSize: firstSegSize [
	"Ignored; this is for Spur's segmented image"
]

{ #category : #'header formats' }
ObjectMemory >> firstStringyFakeFormat [
	"A fake format for the interpreter used to mark indexable strings in
	 the interpreter's at cache.  This is larger than any format."
	^16
]

{ #category : #'object format' }
ObjectMemory >> fixedFieldsOf: oop format: fmt length: wordLength [
"
	NOTE: This code supports the backward-compatible extension to 8 bits of instSize.
	When we revise the image format, it should become...
	^ (classFormat >> 2 bitAnd: 16rFF) - 1
"
	| class classFormat |
	<inline: true>
	((fmt > self lastPointerFormat) or: [fmt = self arrayFormat]) ifTrue: [^0].  "indexable fields only"
	fmt < 2 ifTrue: [^wordLength].  "fixed fields only (zero or more)"
	
	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOfNonImm: oop.
	classFormat := self formatOfClass: class.
	^(classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1
]

{ #category : #'interpreter access' }
ObjectMemory >> floatObjectOf: aFloat [
	| newFloatObj |
	<inline: false>
	<var: #aFloat type: #double>
	newFloatObj := self instantiateSmallClass: (self splObj: ClassFloat) sizeInBytes: (self sizeof: #double)+self baseHeaderSize.
	self storeFloatAt: newFloatObj + self baseHeaderSize from: aFloat.
	^newFloatObj
]

{ #category : #'interpreter access' }
ObjectMemory >> floatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or fail if it is not a Float, and answer 0.
	 Note: May be called by translated primitive code."

	| isFloat result |
	<returnTypeC: #double>
	<var: #result type: #double>
	isFloat := self isFloatInstance: oop.
	isFloat ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + self baseHeaderSize into: result.
		 ^result].
	self primitiveFail.
	^0.0
]

{ #category : #'forward compatibility' }
ObjectMemory >> followField: fieldIndex ofObject: anObject [
	"Spur compatibility; in V3 this is a synonym for fetchPointer:ofObject:"
	<inline: true>
	^self fetchPointer: fieldIndex ofObject: anObject
]

{ #category : #'spur compatibility' }
ObjectMemory >> followForwarded: objOop [
	<inline: false>
	self shouldNotImplement.
	^0
]

{ #category : #'spur compatibility' }
ObjectMemory >> followForwardedObjectFields: objOop toDepth: depth [
	<inline: false>
	self shouldNotImplement
]

{ #category : #'spur compatibility' }
ObjectMemory >> followMaybeForwarded: objOop [
	<inline: true>
	^objOop
]

{ #category : #'forward compatibility' }
ObjectMemory >> followObjField: fieldIndex ofObject: anObject [
	<inline: true>
	^self fetchPointer: fieldIndex ofObject: anObject
]

{ #category : #accessing }
ObjectMemory >> forceTenureFlag [
	^forceTenureFlag
]

{ #category : #accessing }
ObjectMemory >> forceTenureFlag: aValue [
	^forceTenureFlag := aValue
]

{ #category : #'object access' }
ObjectMemory >> formatOf: oop [
"       0      no fields
        1      fixed fields only (all containing pointers)
        2      indexable fields only (all containing pointers)
        3      both fixed and indexable fields (all containing pointers)
        4      both fixed and indexable weak fields (all containing pointers).

        5      unused (reserved for ephemerons?)
        6      indexable word fields only (no pointers)
        7      indexable long (64-bit) fields (only in 64-bit images)
 
    8-11      indexable byte fields only (no pointers) (low 2 bits are low 2 bits of size)
   12-15     compiled methods:
                   # of literal oops specified in method header,
                   followed by indexable bytes (same interpretation of low 2 bits as above)
"
	<inline: true>
	^((self baseHeader: oop) >> self instFormatFieldLSB) bitAnd: 16rF
]

{ #category : #'object format' }
ObjectMemory >> formatOfClass: classPointer [
	"**should be in-lined**"
	"Note that, in Smalltalk, the instSpec will be equal to the inst spec
	part of the base header of an instance (without hdr type) shifted left 1.
	In this way, apart from the smallInt bit, the bits
	are just where you want them for the first header word."
	"Callers (must) expect low 2 bits (header type) to be zero!"
	<api>
	<inline: true>
	^(self fetchPointer: InstanceSpecificationIndex ofObject: classPointer) - 1
]

{ #category : #'object access' }
ObjectMemory >> formatOfHeader: header [
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
	<inline: true>
	^header >> self instFormatFieldLSB bitAnd: 16rF
]

{ #category : #'image segment in/out' }
ObjectMemory >> forward: oop to: newOop savingOopAt: oopPtr andHeaderAt: hdrPtr [

	"Make a new entry in the table of saved oops."
	self longAt: oopPtr put: oop.					"Save the oop"
	self longAt: hdrPtr put: (self longAt: oop).	"Save the old header word"

	"Put a forwarding pointer in the old object, flagged with forbidden header type"
	self longAt: oop put: newOop + HeaderTypeFree
]

{ #category : #'gc -- compaction' }
ObjectMemory >> forwardingPointerOf: forwardedObj [
	"Answer the pointer to the given forwardedOop's forwarding block."
	<inline: true>
	^((self longAt: forwardedObj) bitAnd: AllButMarkBitAndTypeMask) << 1
]

{ #category : #become }
ObjectMemory >> freeObject: obj [
	| objHeader |
	objHeader := self baseHeader: obj.
	self freeObject: obj header: objHeader
]

{ #category : #become }
ObjectMemory >> freeObject: obj header: objHeader [
	| objHeaderBytes objHeaderType objSize |
	(self isYoungRootHeader: objHeader) ifTrue:
		[self removeYoungRoot: obj].
	objHeaderType := objHeader bitAnd: TypeMask.
	objHeaderBytes := headerTypeBytes at: objHeaderType.
	(objHeaderType bitAnd: 1) = 1 "HeaderTypeClass or HeaderTypeShort"
		ifTrue: [objSize := objHeader bitAnd: SizeMask]
		ifFalse:
			[objHeaderType = HeaderTypeFree
				ifTrue: [^nil]. "already free"
			objSize := (self sizeHeader: obj) bitAnd: LongSizeMask].
	self assert: (objSize + objHeaderBytes bitAnd: AllButTypeMask) = (objSize + objHeaderBytes).
	self longAt: obj - objHeaderBytes
		put: ((objSize + objHeaderBytes) bitOr: HeaderTypeFree)
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

	<inline: false>
	DoAssertionChecks ifTrue:
		[self reverseDisplayFrom: 0 to: 7.
		 self clearLeakMapAndMapAccessibleObjects.
		 self checkHeapIntegrity].
	self preGCAction: GCModeFull.
	gcStartUsecs := self ioUTCMicrosecondsNow.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self clearRootsTable.
	self initWeakTableForIncrementalGC: false.
	youngStart := self startOfMemory.  "process all of memory"
	self markPhase.
	"Sweep phase returns the number of survivors.
	Use the up-to-date version instead the one from startup."
	totalObjectCount := self sweepPhase.
	self fullCompaction.
	allocationCount := 0.
	statFullGCs := statFullGCs + 1.
	statGCEndTime := self ioMicroMSecs.
	statFullGCUsecs := statFullGCUsecs + (self ioUTCMicrosecondsNow - gcStartUsecs).
	self capturePendingFinalizationSignals.

	youngStart := freeBlock.  "reset the young object boundary"
	self attemptToShrink.
	self postGCAction: GCModeFull.
	DoAssertionChecks ifTrue:
		[self clearLeakMapAndMapAccessibleObjects.
		 self checkHeapIntegrity.
		 self reverseDisplayFrom: 0 to: 7]
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
ObjectMemory >> fwdBlockValid: addr [ 
	"Answer if the given address is a valid forward table entry."
	^(self oop: addr isGreaterThan: endOfMemory)
	   and: [(self oop: addr isLessThanOrEqualTo: fwdTableNext)
	   and: [(addr bitAnd: 3) = 0]]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> fwdTableInit: blkSize [
	"Set the limits for a table of two- or three-word forwarding blocks above the last used oop. The pointer fwdTableNext moves up to fwdTableLast. Used for compaction of memory and become-ing objects. Returns the number of forwarding blocks available."

	| |
	<inline: false>
	"set endOfMemory to just after a minimum-sized free block"
	self setSizeOfFree: freeBlock to: self baseHeaderSize.
	self setEndOfMemory: freeBlock + self baseHeaderSize.

	"make a fake free chunk at endOfMemory for use as a sentinal in memory scans"
	self setSizeOfFree: endOfMemory to: self baseHeaderSize.

	"use all memory free between freeBlock and memoryLimit for forwarding table"
	"Note: Forward blocks must be quadword aligned."
	fwdTableNext := (endOfMemory + self baseHeaderSize + 7) bitAnd: WordMask-7.
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
	fwdFirst := (eom + self baseHeaderSize + 7) bitAnd: WordMask-7.
	self flag: #Dan.  "Above line does not do what it says (quadword is 16 or 32 bytes)"

	fwdLast := memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdLast - fwdFirst) // blkSize  "round down"
]

{ #category : #'image save/restore' }
ObjectMemory >> garbageCollectForSnapshot [
	self incrementalGC. "maximimize space for forwarding table"
	self fullGC.
	self clearRootsTable
]

{ #category : #accessing }
ObjectMemory >> gcBiasToGrow [
	^gcBiasToGrow
]

{ #category : #accessing }
ObjectMemory >> gcBiasToGrow: aValue [
	^gcBiasToGrow := aValue
]

{ #category : #accessing }
ObjectMemory >> gcBiasToGrowGCLimit [
	^gcBiasToGrowGCLimit
]

{ #category : #accessing }
ObjectMemory >> gcBiasToGrowGCLimit: aValue [
	^gcBiasToGrowGCLimit := aValue
]

{ #category : #accessing }
ObjectMemory >> gcBiasToGrowThreshold [
	^gcBiasToGrowThreshold
]

{ #category : #accessing }
ObjectMemory >> gcBiasToGrowThreshold: aValue [
	^gcBiasToGrowThreshold := aValue
]

{ #category : #accessing }
ObjectMemory >> gcStartUsecs [
	^gcStartUsecs
]

{ #category : #accessing }
ObjectMemory >> getHeapGrowthToSizeGCRatio [
	"For compatibility with spur object memory"
	<option: #PharoVM>
	<returnTypeC: #float>
	^ 0
]

{ #category : #contexts }
ObjectMemory >> goodContextSize: oop [
	| numSlots |
	numSlots := self numSlotsOf: oop.
	^numSlots = SmallContextSlots or: [numSlots = LargeContextSlots]
]

{ #category : #accessing }
ObjectMemory >> growHeadroom [
	^growHeadroom
]

{ #category : #accessing }
ObjectMemory >> growHeadroom: aValue [
	^growHeadroom := aValue
]

{ #category : #allocation }
ObjectMemory >> growObjectMemory: delta [ 
	"Attempt to grow the object memory by the given delta 
	amount "
	| limit |
	statGrowMemory := statGrowMemory + 1.
	limit := self sqGrowMemory: memoryLimit By: delta.
	limit = memoryLimit ifFalse:
		[self setMemoryLimit: limit - 24. "remove a tad for safety"
		 self initializeMemoryFirstFree: freeBlock]
]

{ #category : #allocation }
ObjectMemory >> growToAccomodateContainerWithNumSlots: numSlots [
	"Grow memory to accomodate a container (an Array) with numSlots.
	 Grow by at least the growHeadroom.  Supports allInstancesOf: and allObjects."
	| delta |
	delta := (headerTypeBytes at: HeaderTypeSizeAndClass) / self wordSize
			+ 1
			+ numSlots
			* self bytesPerOop.
	self growObjectMemory: (growHeadroom max: delta)
]

{ #category : #'header access' }
ObjectMemory >> hasForwardingBlock: objOop [
	^self isMarked: objOop
]

{ #category : #'header access' }
ObjectMemory >> hasIdentityHash: objOop [
	"Objects gain their identityHash on instantiation in V3."
	<inline: true>
	^true
]

{ #category : #'object format' }
ObjectMemory >> hasSixtyFourBitImmediates [
	"The V3 64-bit memory manager has 64-bit oops, but its SmallIntegers only have
	 31 bits of precision.  The Spur 64-bit memory manager has 61-bit immediates."
	^false
]

{ #category : #'api characterization' }
ObjectMemory >> hasSpurMemoryManagerAPI [
	^false
]

{ #category : #'header access' }
ObjectMemory >> hashBitsOf: oop [

	^ ((self baseHeader: oop) >> HashBitsOffset) bitAnd: HashMaskUnshifted
]

{ #category : #'method access' }
ObjectMemory >> headerIndicatesAlternateBytecodeSet: methodHeader [
	"A negative header selects the alternate bytecode set."
	<api>
	<inline: true>
	^methodHeader signedIntFromLong < 0
]

{ #category : #'header access' }
ObjectMemory >> headerType: oop [

	^(self baseHeader: oop) bitAnd: TypeMask
]

{ #category : #'header access' }
ObjectMemory >> headerTypeOfHeader: header [

	^header bitAnd: TypeMask
]

{ #category : #'gc -- compaction' }
ObjectMemory >> headerWhileForwardingOf: oop [
	"Answer the header of the argument even though
	 it may have its header word in a forwarding block."
	| header fwdBlock |
	<inline: true>
	header := self longAt: oop.
	(header bitAnd: MarkBit) ~= 0 ifTrue:
		["oop is forwarded; get its real header from its forwarding table entry"
		 fwdBlock := (header bitAnd: AllButMarkBitAndTypeMask) << 1.
		 self assert: (self fwdBlockValid: fwdBlock).
		 header := self longAt: fwdBlock + self wordSize].
	^header
]

{ #category : #'image save/restore' }
ObjectMemory >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes.
	 Since the image reading code uses this to detect byte ordering, one
	 must avoid version numbers that are invariant under byte reversal."
	^self wordSize = 4 ifTrue: [6505] ifFalse: [68003]
]

{ #category : #'image segment in/out' }
ObjectMemory >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC)"

	wholeWord := self longAt: (self splObj: SelectorDoesNotUnderstand) + self baseHeaderSize.
		"first data word, 'does' "
	^ self imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #'gc -- compaction' }
ObjectMemory >> incCompBody [
	"Move objects to consolidate free space into one big chunk. Return the newly created free chunk."

	| bytesFreed |
	<inline: false>
	"reserve memory for forwarding table"
	self fwdTableInit: self wordSize*2.  "Two-word blocks"

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
					fwdBlock := self fwdBlockGet: self wordSize*2.
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
	[self oop: oop isLessThan: compEnd] whileTrue:
		[statCompMoveCount := statCompMoveCount + 1.
		next := self objectAfterWhileForwarding: oop.
		(self isFreeObject: oop) ifFalse:
			["a moving object; unwind its forwarding block"
			fwdBlock := self forwardingPointerOf: oop.
			self assert: (self fwdBlockValid: fwdBlock).
			newOop := self longAt: fwdBlock.
			header := self longAt: fwdBlock + self wordSize.
			self longAt: oop put: header. "restore the original header"
			bytesToMove := oop - newOop. "move the oop (including any extra header words) "
			sz := self sizeBitsOf: oop.
			firstWord := oop - (self extraHeaderBytes: oop).
			lastWord := oop + sz - self baseHeaderSize.
			target := firstWord - bytesToMove.
			firstWord to: lastWord by: self wordSize do:
				[:w | 
				self longAt: target put: (self longAt: w).
				target := target + self wordSize]].
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
	self assert: (self objectAfter: newFreeChunk) = (self oopFromChunk: compEnd).
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
	| survivorCount weDidGrow |
	<inline: false>
	rootTableOverflowed ifTrue:
		["root table overflow; cannot do an incremental GC because some roots are missing.
		 (this should be very rare)"
		 statRootTableOverflows := statRootTableOverflows + 1.
		 ^self fullGC].

	DoAssertionChecks ifTrue:
		[self reverseDisplayFrom: 8 to: 15.
		 self checkHeapIntegrity.
		 self checkInterpreterIntegrity.
		 self validate].

	self preGCAction: GCModeNewSpace.
	"incremental GC and compaction"

	gcStartUsecs := self ioUTCMicrosecondsNow.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self initWeakTableForIncrementalGC: true.
	self markPhase.
	self assert: weakRootCount <= WeakRootTableSize.
	1 to: weakRootCount do:[:i| self finalizeReference: (weakRoots at: i)].
	survivorCount := self sweepPhase.
	self incrementalCompaction.
	statAllocationCount := allocationCount.
	allocationCount := 0.
	statIncrGCs := statIncrGCs + 1.
	statGCEndTime := self ioMicroMSecs.
	statIGCDeltaUsecs := self ioUTCMicrosecondsNow - gcStartUsecs.
	statIncrGCUsecs := statIncrGCUsecs + statIGCDeltaUsecs.
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
			(((self sizeOfFree: freeBlock) < growHeadroom) and: 
				[gcBiasToGrow > 0]) 
				ifTrue: [self biasToGrow.
						weDidGrow := true].
			youngStart := freeBlock].
	self attemptToShrink.
	self postGCAction: GCModeNewSpace.
	DoAssertionChecks ifTrue:
		[self validate.
		 self checkHeapIntegrity.
		 self checkInterpreterIntegrity.
		 self reverseDisplayFrom: 8 to: 15].
	weDidGrow ifTrue: [self biasToGrowCheckGCLimit]
]

{ #category : #'header formats' }
ObjectMemory >> indexablePointersFormat [
	<api>
	<cmacro>
	^3
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
	self assert: fwdBlock ~= nil. "ran out of forwarding blocks in become"
	self assert: (originalHeader bitAnd: MarkBit) = 0. "'object already has a forwarding table entry"
	originalHeaderType := originalHeader bitAnd: TypeMask.
	self longAt: fwdBlock put: newOop.
	self longAt: fwdBlock + self wordSize put: originalHeader.
	backFlag ifTrue: [self longAt: fwdBlock + (self wordSize*2) put: oop].
	self longAt: oop put: (fwdBlock >> 1 bitOr: (MarkBit bitOr: originalHeaderType))
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> initWeakTableForIncrementalGC: trueIfIncrementalGC [
	"The weakRoots table is only used for incrementalGC.
	 Enable it by setting weakRootCount to 0.
	 Disable it by making it negative."
	weakRootCount := trueIfIncrementalGC ifTrue: [0] ifFalse: [-1]
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
	^nil
]

{ #category : #initialization }
ObjectMemory >> initialize [
	<doNotGenerate>
	"Initialize ObjectMemory when simulating the VM inside Smalltalk."
	super initialize.
	headerTypeBytes := CArrayAccessor on: HeaderTypeExtraBytes.
	rootTable := Array new: RootTableSize.
	weakRoots := Array new: WeakRootTableSize.
	remapBuffer := Array new: RemapBufferSize
]

{ #category : #initialization }
ObjectMemory >> initializeMemoryFirstFree: firstFree [ 
	"Initialize endOfMemory to the top of oop storage space, reserving some space for forwarding blocks, and create the freeBlock from which space is allocated. Also create a fake free chunk at endOfMemory to act as a sentinal for memory scans. "
	"Note: The amount of space reserved for forwarding blocks should be chosen to ensure that incremental compactions can usually be done in a single pass. However, there should be enough forwarding blocks so a full compaction can be done in a reasonable number of passes, say ten. (A full compaction requires N object-moving passes, where N = number of non-garbage objects / number of forwarding blocks). 
	di 11/18/2000 Re totalObjectCount: Provide a margin of one byte per object to be used for forwarding pointers at GC time. Since fwd blocks are 8 bytes, this means an absolute worst case of 8 passes to compact memory. In most cases it will be adequate to do compaction in a single pass. "
	| fwdBlockBytes |
	"reserve space for forwarding blocks"
	fwdBlockBytes := totalObjectCount bitAnd: WordMask - self wordSize + 1.
	(self oop: memoryLimit - fwdBlockBytes isGreaterThanOrEqualTo: firstFree + self baseHeaderSize)
		ifFalse: ["reserve enough space for a minimal free block of BaseHeaderSize bytes"
			fwdBlockBytes := memoryLimit - (firstFree + self baseHeaderSize)].

	"set endOfMemory and initialize freeBlock"
	self setEndOfMemory: memoryLimit - fwdBlockBytes.
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
	"Catch mis-initializations leading to bad translations to C"
	self assert: self baseHeaderSize = self wordSize.

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
	rootTableOverflowed := false.
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
	statFullGCUsecs := 0.
	statIncrGCs := 0.
	statIncrGCUsecs := 0.
	statTenures := 0.
	statRootTableOverflows := 0.
	statGrowMemory := 0.
	statShrinkMemory := 0.
	forceTenureFlag := 0.
	gcBiasToGrow := 0.
	gcBiasToGrowGCLimit := 0.
	extraRootCount := 0.
	gcStartUsecs := 0
]

{ #category : #'object format' }
ObjectMemory >> instSpecOfClass: classPointer [
	"This field in a class's format inst var corresponds to the 4-bit format field stored in every object header"

	^self formatOfHeader: (self formatOfClass: classPointer)
]

{ #category : #'primitive support' }
ObjectMemory >> instanceAfter: objOop [
	"Answer the next instance of objOop's class in the canonical enumeration order,
	 if it exists, otherwise answer nil."
	| classPointer subsequentObject |
	classPointer := self fetchClassOfNonImm: objOop.
	subsequentObject := self objectAfter: objOop.
	[self oop: subsequentObject isLessThan: self freeStart] whileTrue:
		[((self isFreeObject: subsequentObject) not
		  and: [(self fetchClassOfNonImm: subsequentObject) = classPointer]) ifTrue:
			[^subsequentObject].
		 subsequentObject := self objectAfter: subsequentObject].
	^nil
]

{ #category : #'interpreter access' }
ObjectMemory >> instanceSizeOf: classObj [
	<api>
	"Answer the number of slots in a class.  For example the instanceSizeOf: 
	 ClassPoint is 2, for the x & y slots. The instance size of non-pointer classes is 0."
	| classHdr sizeHiBits byteSize |
	self assert: (self addressCouldBeObj: classObj).

	classHdr := self formatOfClass: classObj. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits := classHdr >> 9 bitAnd: 16r300.
	byteSize := (classHdr bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"
	^byteSize - self baseHeaderSize / self wordSize
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateClass: classPointer indexableSize: size [
	"NOTE: This method supports the backward-compatible split instSize field of the 
	class format word. The sizeHiBits will go away and other shifts change by 2 
	when the split fields get merged in an (incompatible) image change."
	<api>
	| hash header1 header2 cClass byteSize format binc header3 hdrSize sizeHiBits bm1 classFormat |
	<inline: false>
	self assert: size >= 0. "'cannot have a negative indexable field count"
	hash := self newObjectHash.
	classFormat := self formatOfClass: classPointer.
	"Low 2 bits are 0"
	header1 := (classFormat bitAnd: 16r1FF00) bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset.
	header2 := classPointer.
	sizeHiBits := (classFormat bitAnd: 16r60000) >> 9.
	cClass := header1 bitAnd: CompactClassMask. "compact class field from format word"
	byteSize := (classFormat bitAnd: SizeMask + Size4Bit) + sizeHiBits.
		"size in bytes -- low 2 bits are 0"
	"Note this byteSize comes from the format word of the class which is pre-shifted
		to 4 bytes per field.  Need another shift for 8 bytes per word..."
	byteSize := byteSize << (self shiftForWord-2).
	format := self formatOfHeader: classFormat.
	self flag: #sizeLowBits.
	format < self firstByteFormat
		ifTrue:
			[format = self firstLongFormat
				ifTrue: "long32 bitmaps"
					[bm1 := self wordSize-1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: LongSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: "Arrays and 64-bit bitmaps"
					[byteSize := byteSize + (size * self wordSize)]]
		ifFalse:
			["Strings and Methods"
			bm1 := self wordSize-1.
			byteSize := byteSize + size + bm1 bitAnd: LongSizeMask. "round up"
			binc := bm1 - (size + bm1 bitAnd: bm1). "odd bytes"
			"low bits of byte size go in format field"
			header1 := header1 bitOr: (binc bitAnd: 3) << self instFormatFieldLSB.
			"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
			header1 := header1 bitOr: (binc bitAnd: 4)].
	byteSize > 255 "requires size header word/full header"
		ifTrue: [header3 := byteSize. hdrSize := 3]
		ifFalse: [header1 := header1 bitOr: byteSize. hdrSize := cClass = 0 ifTrue: [2] ifFalse: [1]].
	^self allocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3 doFill: true format: format
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateContext: classPointer sizeInBytes: sizeInBytes [ 
	"This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word."
	| hash header1 header2 hdrSize |
	hash := self newObjectHash.
	header1 := (hash bitAnd: HashMaskUnshifted) << HashBitsOffset bitOr: (self formatOfClass: classPointer).
	header2 := classPointer.
	(header1 bitAnd: CompactClassMask) > 0 "are contexts compact?"
		ifTrue: [hdrSize := 1]
		ifFalse: [hdrSize := 2].
	sizeInBytes <= SizeMask
		ifTrue: ["OR size into header1.  Must not do this if size > SizeMask"
				header1 := header1 + (sizeInBytes - (header1 bitAnd: SizeMask))]
		ifFalse: [hdrSize := 3.
				"Zero the size field of header1 if large"
				header1 := header1 - (header1 bitAnd: SizeMask)].
self flag: #Dan.  "Check details of context sizes"
	^ self allocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: LargeContextSize doFill: false format: 0
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
	(sizeInBytes bitAnd: (self wordSize-1)) = 0 ifFalse:
		[self error: 'size must be integral number of words'].
	hash := self newObjectHash.
	header1 := (hash bitAnd: HashMaskUnshifted) << HashBitsOffset bitOr: (self formatOfClass: classPointer).
	header2 := classPointer.
	hdrSize := (header1 bitAnd: CompactClassMask) > 0 "is this a compact class"
				ifTrue: [1]
				ifFalse: [2].
	header1 := header1 + (sizeInBytes - (header1 bitAnd: SizeMask+Size4Bit)).
	^ self allocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: 0 doFill: false format: 0
]

{ #category : #'interpreter access' }
ObjectMemory >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."
	<returnTypeC: #sqInt>
	^self
		cCode: [(value << 1) + 1]
		inSmalltalk: [value >= 0
						ifTrue: [(value << 1) + 1]
						ifFalse: [((16r80000000 + value) << 1) + 1]]
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

{ #category : #simulation }
ObjectMemory >> interpreter [
	<doNotGenerate>
	^self
]

{ #category : #simulation }
ObjectMemory >> ioLoadModule: moduleNameIndex OfLength: moduleLength [
	<doNotGenerate>
	<returnTypeC: #'void *'>
	"Dummy - provided by support code"
	^0
]

{ #category : #'object access' }
ObjectMemory >> is: oop instanceOf: classOop [
	"Answer if oop is an instance of the given class. If the class has a (non-zero)
	 compactClassIndex use that to speed up the check."

	<inline: true>
	(self isIntegerObject: oop) ifTrue:
		[^classOop = (self splObj: ClassSmallInteger)].

	^self isClassOfNonImm: oop equalTo: classOop
]

{ #category : #'object access' }
ObjectMemory >> is: oop instanceOf: classOop compactClassIndex: compactClassIndex [
	"Answer if oop is an instance of the given class. If the class has a (non-zero)
	 compactClassIndex use that to speed up the check.  N.B. Inlining should
	 result in classOop not being accessed if oop's compact class index and
	 compactClassIndex are non-zero."

	<inline: true>
	(self isIntegerObject: oop) ifTrue:
		[^false].

	^self isClassOfNonImm: oop equalTo: classOop compactClassIndex: compactClassIndex
]

{ #category : #'header access' }
ObjectMemory >> isArray: oop [
	"Answer true if this is an indexable object with pointer elements, e.g., an array"
	^(self isNonIntegerObject: oop) and:[self isArrayNonImm: oop]
]

{ #category : #'header access' }
ObjectMemory >> isArrayNonImm: oop [
	<api>
	"Answer if this is an indexable object with pointer elements, e.g., an array"
	^ (self formatOf: oop) = 2
]

{ #category : #'header access' }
ObjectMemory >> isBytes: oop [
	"Answer true if the argument contains indexable bytes. See comment in formatOf:"
	"Note: Includes CompiledMethods."
	^(self isNonIntegerObject: oop) and:[self isBytesNonImm: oop]
]

{ #category : #'header access' }
ObjectMemory >> isBytesNonImm: oop [
	"Answer true if the argument contains indexable bytes. See comment in formatOf:"
	"Note: Includes CompiledMethods."

	^(self formatOf: oop) >= self firstByteFormat
]

{ #category : #'interpreter access' }
ObjectMemory >> isCharacterObject: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (self splObj: ClassCharacter) is expanded in-place
	 and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^self
		is: oop
		instanceOf: (self splObj: ClassCharacter) 
		compactClassIndex: 0
]

{ #category : #'primitive support' }
ObjectMemory >> isCharacterValue: anInteger [
	<api>
	^self isInRangeCharacterCode: anInteger
]

{ #category : #'header access' }
ObjectMemory >> isClassOfNonImm: oop equalTo: classOop [
	"Answer if the given (non-immediate) object is an instance of the given class."

	| ccIndex cl |
	<inline: true>
	self assert: (self isNonImmediate: oop).

	cl := (ccIndex := self compactClassIndexOf: oop) = 0
			ifTrue: [(self classHeader: oop) bitAnd: AllButTypeMask]
			ifFalse: [self compactClassAt: ccIndex].
	^cl = classOop
]

{ #category : #'object access' }
ObjectMemory >> isClassOfNonImm: oop equalTo: classOop compactClassIndex: compactClassIndex [
	"Answer if the given (non-immediate) object is an instance of the given class
	 that may have a compactClassIndex (if compactClassIndex is non-zero).
	 N.B. Inlining and/or compiler optimization should result in classOop not being
	 accessed if oop's compact class index and compactClassIndex are non-zero.
	 N.B.  Generally one cannot assume that if compactClassIndex is non-zero the
	 instances of the corresponding class always have the compactClassIndex
	 because the compact class index is only non-zero in short header instances."

	| ccIndex |
	<inline: true>
	self assert: (self isIntegerObject: oop) not.

	ccIndex := self compactClassIndexOf: oop.
	ccIndex = 0 ifTrue:
		[^((self classHeader: oop) bitAnd: AllButTypeMask) = classOop].
	compactClassIndex ~= 0 ifTrue:
		[^compactClassIndex = ccIndex].
	^classOop = (self compactClassAt: ccIndex)
]

{ #category : #'interpreter access' }
ObjectMemory >> isCompiledMethod: oop [
    "Answer whether the argument object is of compiled method format"
	<api>
    ^(self formatOf: oop) >= self firstCompiledMethodFormat
]

{ #category : #'interpreter access' }
ObjectMemory >> isCompiledMethodFormat: format [
	^format >= self firstCompiledMethodFormat
]

{ #category : #'interpreter access' }
ObjectMemory >> isCompiledMethodHeader: objHeader [
    "Answer whether the argument header has compiled method format"
    ^(self formatOfHeader: objHeader) >= self firstCompiledMethodFormat
]

{ #category : #contexts }
ObjectMemory >> isContext: oop [
	<inline: true>
	^(self isNonIntegerObject: oop) and: [self isContextHeader: (self baseHeader: oop)]
]

{ #category : #contexts }
ObjectMemory >> isContextHeader: aHeader [
	<inline: true>
	"c.f. {BlockContext. MethodContext. PseudoContext} collect: [:class| class -> class indexIfCompact]"
	^(self compactClassIndexOfHeader: aHeader) = 13			"BlockContext"
		or: [(self compactClassIndexOfHeader: aHeader) = 14]		"MethodContext"
]

{ #category : #contexts }
ObjectMemory >> isContextNonImm: oop [
	<inline: true>
	^self isContextHeader: (self baseHeader: oop)
]

{ #category : #'interpreter access' }
ObjectMemory >> isFloatInstance: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassFloat) is expanded in-place and is
	 _not_ evaluated if oop has a non-zero CompactClassIndex."
	^self
		is: oop
		instanceOf: (self splObj: ClassFloat) 
		compactClassIndex: ClassFloatCompactIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> isForwarded: oop [
	"Compatibility wth SpurMemoryManager.  In ObjectMemory, no forwarding pointers
	 are visible to the VM."
	<api>
	<cmacro: '(oop) false'>
	<inline: true>
	^false
]

{ #category : #'interpreter access' }
ObjectMemory >> isForwardedClassTag: classTag [
	"Compatibility wth SpurMemoryManager.  In ObjectMemory, no forwarding pointers
	 are visible to the VM."
	<inline: true>
	^false
]

{ #category : #'header access' }
ObjectMemory >> isFreeObject: oop [

	^ (self headerType: oop) = HeaderTypeFree
]

{ #category : #'interpreter access' }
ObjectMemory >> isImmediate: anOop [
	<api>
	^self isIntegerObject: anOop
]

{ #category : #'interpreter access' }
ObjectMemory >> isImmediateCharacter: objectPointer [

	^false
]

{ #category : #'interpreter access' }
ObjectMemory >> isImmediateFloat: oop [
	^false
]

{ #category : #'gc -- compaction' }
ObjectMemory >> isImmutableWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	the value of the isImmutable flag in the object in spite of this obstacle. "
	| header fwdBlock |
	<inline: true>
	header := self longAt: oop.
	(header bitAnd: MarkBit) ~= 0 ifTrue:
		["oop is forwarded; get its real header from its forwarding table entry"
		fwdBlock := (header bitAnd: AllButMarkBitAndTypeMask) << 1.
		DoAssertionChecks ifTrue:
			[self fwdBlockValidate: fwdBlock].
		header := self longAt: fwdBlock + self wordSize].
	^(header bitAnd: ImmutabilityBit) ~= 0
]

{ #category : #finalization }
ObjectMemory >> isInFinalizationList: oop head: listHead [
	"it is known that oop's first fixed slot points to an instance of special object - ClassWeakFinalizer ,
	so it is safe to assume that we can iterate over it to figure out if oop is already in that list"
	<option: #PharoVM>
	| listItem |

	listItem := listHead.
	
	[ listItem == self nilObject ] whileFalse: [
		listItem == oop ifTrue: [ ^ true ].
		listItem := self fetchPointer: 1 ofObject: listItem.   
	].
	^ false

]

{ #category : #'plugin support' }
ObjectMemory >> isInMemory: address [ 
	"Return true if the given address is in ST object memory"
	^ (self oop: address isGreaterThanOrEqualTo: self startOfMemory)
		and: [self oop: address isLessThan: endOfMemory]
]

{ #category : #'interpreter access' }
ObjectMemory >> isInRangeCharacterCode: characterCode [
	^characterCode between: 0 and: 255
]

{ #category : #'object format' }
ObjectMemory >> isIndexable: oop [
	^(self formatOf: oop) >= 2
]

{ #category : #'header access' }
ObjectMemory >> isIndexableFormat: format [
	^format >= self arrayFormat
	  and: [format <= self weakArrayFormat
			or: [format >= self firstLongFormat]]
]

{ #category : #'interpreter access' }
ObjectMemory >> isInstanceOfClassLargeNegativeInteger: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassLargeNegativeInteger) is expanded
	 in-place and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^self
		is: oop
		instanceOf: (self splObj: ClassLargeNegativeInteger) 
		compactClassIndex: ClassLargeNegativeIntegerCompactIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> isInstanceOfClassLargePositiveInteger: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassLargePositiveInteger) is expanded
	 in-place and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^self
		is: oop
		instanceOf: (self splObj: ClassLargePositiveInteger) 
		compactClassIndex: ClassLargePositiveIntegerCompactIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> isIntegerObject: objectPointer [

	^ (objectPointer bitAnd: 1) > 0
]

{ #category : #'interpreter access' }
ObjectMemory >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value.
	 In C, use a shift and XOR to set the sign bit if and only if the top two bits of the given
	 value are the same, then test the sign bit. Note that the top two bits are equal for
	 exactly those integers in the range that can be represented in 31-bits or 63-bits."
	<api>
	^self
		cCode: [(intValue asUnsignedInteger bitXor: (intValue asUnsignedInteger << 1)) asInteger >= 0]
		inSmalltalk: [intValue >= self minSmallInteger and: [intValue <= self maxSmallInteger]]
]

{ #category : #'interpreter access' }
ObjectMemory >> isLargeIntegerInstance: oop [
	<inline: true>
	^(self isInstanceOfClassLargePositiveInteger: oop)
		or: [self isInstanceOfClassLargeNegativeInteger: oop]
]

{ #category : #'header access' }
ObjectMemory >> isMarked: oop [
	<api>
	"Answer if oop's mark bit is set"
	^((self longAt: oop) bitAnd: MarkBit) ~= 0
]

{ #category : #contexts }
ObjectMemory >> isMethodContextHeader: aHeader [
	<inline: true>
	"c.f. {BlockContext. MethodContext. PseudoContext} collect: [:class| class -> class indexIfCompact]"
	^(self compactClassIndexOfHeader: aHeader) = ClassMethodContextCompactIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonImmediate: anOop [
	^self isNonIntegerObject: anOop
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonIntegerImmediate: oop [
	"ObjectMemory only has integer immedates"
	<inline: true>
	^false
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonIntegerNonImmediate: oop [
	"ObjectMemory only has integer immedates"
	<inline: true>
	^true
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonIntegerObject: objectPointer [
	<api>
	^(objectPointer bitAnd: 1) = 0
]

{ #category : #'header access' }
ObjectMemory >> isObjImmutable: anOop [
	<inline: true>
	^self cppIf: IMMUTABILITY
		ifTrue: [((self baseHeader: anOop) bitAnd: ImmutabilityBit hex) ~= 0]
		ifFalse: [false]
]

{ #category : #'header access' }
ObjectMemory >> isObjMutable: anOop [
	<inline: true>
	^(self isObjImmutable: anOop) not
]

{ #category : #'gc -- compaction' }
ObjectMemory >> isObjectForwarded: oop [ 
	"Answer if the given object has a forwarding table entry 
	 during a compaction or become operation."
	^(self isNonIntegerObject: oop) and: [self isMarked: oop]
]

{ #category : #'interpreter access' }
ObjectMemory >> isOopCompiledMethod: oop [
	"Answer whether the oop is an object of compiled method format"
	<api>
	^(self isNonIntegerObject: oop)
	 and: [(self formatOf: oop) >= self firstCompiledMethodFormat]
]

{ #category : #'interpreter access' }
ObjectMemory >> isOopForwarded: oop [
	"Compatibility wth SpurMemoryManager.  In ObjectMemory, no forwarding pointers
	 are visible to the VM."
	<inline: true>
	^false
]

{ #category : #'header access' }
ObjectMemory >> isOopImmutable: anOop [
	<api>
	^(self isIntegerObject: anOop)
	  or: [self isObjImmutable: anOop]
]

{ #category : #'header access' }
ObjectMemory >> isOopMutable: anOop [
	<api>
	^(self isIntegerObject: anOop) not
	  and: [(self isObjImmutable: anOop) not]
]

{ #category : #'primitive support' }
ObjectMemory >> isPinned: objOop [
	"For forward-compatibility with Spur.  Answer false; ObjectMemory does not support pinning."
	<api>
	^false
]

{ #category : #'header access' }
ObjectMemory >> isPointers: oop [
	"Answer true if the argument has only fields that can hold oops. See comment in formatOf:"

	^(self isNonIntegerObject: oop) and:[self isPointersNonImm: oop]
]

{ #category : #'header access' }
ObjectMemory >> isPointersFormat: format [
	^format <= self lastPointerFormat
]

{ #category : #'header access' }
ObjectMemory >> isPointersNonImm: oop [
	"Answer if the argument has only fields that can hold oops. See comment in formatOf:"

	^(self formatOf: oop) <= self lastPointerFormat
]

{ #category : #'interpreter access' }
ObjectMemory >> isSemaphoreObj: anObj [
	^(self fetchClassOfNonImm: anObj) = (self splObj: ClassSemaphore)
]

{ #category : #'interpreter access' }
ObjectMemory >> isSemaphoreOop: anOop [
	^(self isNonImmediate: anOop)
	 and: [self isSemaphoreObj: anOop]
]

{ #category : #'header access' }
ObjectMemory >> isWeak: oop [
	"Answer true if the argument has only weak fields that can hold oops. See comment in formatOf:"
	^(self isNonIntegerObject: oop) and: [self isWeakNonImm: oop]
]

{ #category : #'header access' }
ObjectMemory >> isWeakNonImm: oop [
	"Answer if the argument has only weak fields that can hold oops. See comment in formatOf:"
	^(self formatOf: oop) = self weakArrayFormat
]

{ #category : #'header access' }
ObjectMemory >> isWords: oop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self isNonIntegerObject: oop) and: [self isWordsNonImm: oop]
]

{ #category : #'header access' }
ObjectMemory >> isWordsNonImm: oop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^ (self formatOf: oop) = self firstLongFormat
]

{ #category : #'header access' }
ObjectMemory >> isWordsOrBytes: oop [
	"Answer if the contains only indexable words or bytes (no oops). See comment in formatOf:"
	"Note: Excludes CompiledMethods."
	^(self isNonIntegerObject: oop) and: [self isWordsOrBytesNonImm: oop]
]

{ #category : #'header access' }
ObjectMemory >> isWordsOrBytesNonImm: oop [
	"Answer if the contains only indexable words or bytes (no oops). See comment in formatOf:"
	"Note: Excludes CompiledMethods."

	| fmt |
	fmt := self formatOf: oop.
	^fmt = self firstLongFormat
	  or: [fmt >= self firstByteFormat
		  and: [fmt < self firstCompiledMethodFormat]]
]

{ #category : #'interpreter access' }
ObjectMemory >> isYoung: oop [
	<api>
	^(self isNonIntegerObject: oop)
	   and: [self oop: oop isGreaterThanOrEqualTo: youngStart]
]

{ #category : #'garbage collection' }
ObjectMemory >> isYoungRoot: oop [
	"Answer if oop is a root for objects in youngSpace"
	^self isYoungRootHeader: (self baseHeader: oop)
]

{ #category : #'garbage collection' }
ObjectMemory >> isYoungRootHeader: header [
	"Answer if oop is a root for objects in youngSpace"
	^(header bitAnd: RootBit) ~= 0
]

{ #category : #accessing }
ObjectMemory >> lastHash [
	^lastHash
]

{ #category : #accessing }
ObjectMemory >> lastHash: aValue [
	^lastHash := aValue
]

{ #category : #'header access' }
ObjectMemory >> lastPointerFormat [
	"N.B. 5 is unused and could be used for ephemerons.
		7 is unused and could be used for 64-bit indexable."
	^4
]

{ #category : #'object enumeration' }
ObjectMemory >> lastPointerOf: objOop [ 
	"Return the byte offset of the last pointer field of the given object.  
	Works with CompiledMethods, as well as ordinary objects. 
	Can be used even when the type bits are not correct."
	<api>
	<inline: true>
	| fmt sz header contextSize |
	header := self baseHeader: objOop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextHeader: header])
					ifTrue: ["contexts end at the stack pointer"
						contextSize := self fetchStackPointerOf: objOop.
						^ CtxtTempFrameStart + contextSize * self wordSize].
				sz := self sizeBitsOfSafe: objOop.
				^sz - self baseHeaderSize "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	header := self methodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> lastPointerOf: objOop recordWeakRoot: recordWeakRoot [ "<Boolean>"
	"Return the byte offset of the last pointer field of the given object.  
	 Works with CompiledMethods, as well as ordinary objects. 
	 Can be used even when the type bits are not correct.
	 This is a version of lastPointerOf: for markAndTrace:."
	| fmt sz header contextSize |
	<inline: true>
	header := self baseHeader: objOop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[fmt >= self indexablePointersFormat ifTrue:
			[fmt = self lastPointerFormat ifTrue:
				[(recordWeakRoot and: [weakRootCount >= 0]) ifTrue:
					["And remember as weak root"
					 (weakRootCount := weakRootCount + 1) <= WeakRootTableSize ifFalse:
						[self error: 'weakRoots table overflow'].
					 weakRoots at: weakRootCount put: objOop].
				"Do not trace the object's indexed fields if it's a weak class"
				^(self nonWeakFieldsOf: objOop) * self bytesPerOop].
			"So fmt is 3"
			(self isContextHeader: header) ifTrue:
				["contexts end at the stack pointer avoiding having to init fields beyond it"
				 contextSize := self fetchStackPointerOf: objOop.
				 ^CtxtTempFrameStart + contextSize * self bytesPerOop]].
		 sz := self sizeBitsOfSafe: objOop.
		 ^sz - self baseHeaderSize  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	header := self methodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'object enumeration' }
ObjectMemory >> lastPointerOfMethodHeader: methodHeader [ 
	"Answer the byte offset of the last pointer field of a
	 CompiledMethod with the given header."
	<inline: true>
	^(self literalCountOfMethodHeader: methodHeader)
	  + LiteralStart - 1 * self bytesPerOop + self baseHeaderSize
]

{ #category : #'gc -- compaction' }
ObjectMemory >> lastPointerWhileForwarding: objOop [ 
	"The given object may have its header word in a forwarding block. Find  
	the offset of the last pointer in the object in spite of this obstacle. "
	| header fmt size contextSize |
	<inline: true>
	header := self headerWhileForwardingOf: objOop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := self nacFetchStackPointerOf: objOop.
			self assert: ReceiverIndex + contextSize < (self lengthOf: objOop baseHeader: header format: fmt).
			^CtxtTempFrameStart + contextSize * self wordSize].
		"do sizeBitsOf: using the header we obtained"
		(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [size := (self sizeHeader: objOop) bitAnd: AllButTypeMask]
			ifFalse: [size := header bitAnd: SizeMask].
		^size - self baseHeaderSize].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"
	"CompiledMethod: contains both pointers and bytes"
	self assert: (self isCompiledMethodHeader: header).
	header := self noCheckMethodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'object access' }
ObjectMemory >> lengthOf: oop [
	"Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result."

	<api>
	| header |
	<inline: true>
	header := self baseHeader: oop.
	^self lengthOf: oop baseHeader: header format: (self formatOfHeader: header)
]

{ #category : #'object access' }
ObjectMemory >> lengthOf: oop baseHeader: hdr format: fmt [
	"Return the number of fixed and indexable bytes, words, or object pointers in the
	given object. Assume the given oop is not an integer. For a CompiledMethod, the size
	of the method header (in bytes) should be subtracted from the result of this method."

	| sz |
	<inline: true>
	(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ sz := (hdr bitAnd: SizeMask)].
	sz := sz - (hdr bitAnd: Size4Bit).
	fmt <= self lastPointerFormat
		ifTrue: [ ^ (sz - self baseHeaderSize) >> self shiftForWord "words"].
	^fmt < self firstByteFormat
		ifTrue: [(sz - self baseHeaderSize) >> 2 "32-bit longs"]
		ifFalse: [(sz - self baseHeaderSize) - (fmt bitAnd: 3) "bytes"]
]

{ #category : #'debug support' }
ObjectMemory >> lengthOfMaybeImmediate: oop [
	"for the message send breakpoint; selectors can be immediates."
	<inline: false>
	(self isImmediate: oop) ifTrue: [^0].
	^self lengthOf: oop
]

{ #category : #'method access' }
ObjectMemory >> literalCountOf: methodPointer [
	<api>
	^self literalCountOfMethodHeader: (self methodHeaderOf: methodPointer)
]

{ #category : #'memory access' }
ObjectMemory >> literalCountOfMethodHeader: header [
	<inline: true>
	self assert: (self isIntegerObject: header).
	^header >> 10 bitAnd: 16rFF
]

{ #category : #'interpreter access' }
ObjectMemory >> loadFloatOrIntFrom: floatOrInt [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	 If it is a Float, then load its value and return it.
	 Otherwise fail -- ie return with primErrorCode non-zero."

	<inline: true>
	<returnTypeC: #double>

	(self isIntegerObject: floatOrInt) ifTrue:
		[^(self integerValueOf: floatOrInt) asFloat].
	^self floatValueOf: floatOrInt
]

{ #category : #'image segment in/out' }
ObjectMemory >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of one word, i.e. retaining the version stamp.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

	| endSeg segOop fieldPtr fieldOop doingClass lastPtr extraSize mapOop lastOut outPtr hdrTypeBits header data |
	<inline: false>
	<var: #endSeg type: #usqInt>
	<var: #segOop type: #usqInt>
	<var: #fieldPtr type: #usqInt>
	<var: #lastOut type: #usqInt>
	<var: #outPtr type: #usqInt>
	<var: #lastPtr type: #usqInt>

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	lastOut := outPointerArray + (self lastPointerOf: outPointerArray).
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - self baseHeaderSize.

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + self baseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
		"Not readable -- try again with reversed bytes..."
		[self reverseBytesFrom: segmentWordArray + self baseHeaderSize to: endSeg + self wordSize.
		data := self longAt: segmentWordArray + self baseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
			"Still NG -- put things back and fail"
			[self reverseBytesFrom: segmentWordArray + self baseHeaderSize to: endSeg + self wordSize.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^PrimErrBadArgument]].
	"Reverse the Byte type objects if the data is from opposite endian machine.
	 Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal."
	(data >> 16) = (self imageSegmentVersion >> 16)
		ifFalse: "Reverse the byte-type objects once"
			[segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
				 "Oop of first embedded object"
			self byteSwapByteObjectsFrom: segOop
				to: endSeg + self wordSize
				flipFloatsIf: false].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - self wordSize.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + self baseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue:
			[DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^PrimErrBadIndex "out of bounds"].

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits := self headerType: fieldPtr.
				fieldOop := fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue:
					["Integer -- nothing to do"
					fieldPtr := fieldPtr + self wordSize]
				ifFalse:
					[(fieldOop bitAnd: 3) = 0 ifFalse:
						[^PrimErrBadIndex "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop := fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr := outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue:
									[^PrimErrBadIndex "out of bounds"].
								mapOop := self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + 8.
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + self wordSize].
					segOop < youngStart ifTrue:
						[self possibleRootStoreInto: segOop value: mapOop]]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse:
			[^PrimErrInappropriate "inconsistency"].
		fieldPtr := segOop + self baseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse:
				[^PrimErrInappropriate "inconsistency"].
			fieldPtr := fieldPtr + self wordSize].
		segOop := self objectAfter: segOop].

	"Truncate the segment word array to size = BytesPerWord (vers stamp only)"
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: self baseHeaderSize + self wordSize + hdrTypeBits]
		ifFalse: [header := self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: SizeMask) + self baseHeaderSize + self wordSize].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize
]

{ #category : #'debug printing' }
ObjectMemory >> longPrintInstancesOf: aClassOop [
	"Scan the heap printing the oops of any and all objects that are instances of aClassOop"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[(self fetchClassOfNonImm: oop) = aClassOop ifTrue:
			[self longPrintOop: oop; cr].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #accessing }
ObjectMemory >> lowSpaceThreshold [
	^lowSpaceThreshold
]

{ #category : #accessing }
ObjectMemory >> lowSpaceThreshold: aValue [
	^lowSpaceThreshold := aValue
]

{ #category : #'garbage collection' }
ObjectMemory >> lowestFreeAfter: chunk [ 
	"Return the first free block after the given chunk in memory."
	| oop oopHeader oopHeaderType oopSize |
	<inline: false>
	oop := self oopFromChunk: chunk.
	[self oop: oop isLessThan: endOfMemory] whileTrue:
		[oopHeader := self baseHeader: oop.
		 oopHeaderType := oopHeader bitAnd: TypeMask.
		 oopHeaderType = HeaderTypeFree ifTrue:
			[^oop].
		 oopHeaderType = HeaderTypeSizeAndClass
			ifTrue: [oopSize := (self sizeHeader: oop) bitAnd: AllButTypeMask]
			ifFalse: [oopSize := oopHeader bitAnd: SizeMask].
		 oop := self oopFromChunk: oop + oopSize].
	self error: 'expected to find at least one free object'.
	^nil
]

{ #category : #'gc -- compaction' }
ObjectMemory >> mapPointersInObjectsFrom: memStart to: memEnd [
	"Use the forwarding table to update the pointers of all non-free objects in the given range of memory.
	 Also remap pointers in root objects which may contains pointers into the given memory range, and
	 don't forget to flush the method cache based on the range."
	<inline: false>
	(self shouldRemapObj: nilObj) ifTrue:
		[nilObj := self remapObj: nilObj].
	(self shouldRemapObj: falseObj) ifTrue:
		[falseObj := self remapObj: falseObj].
	(self shouldRemapObj: trueObj) ifTrue:
		[trueObj := self remapObj: trueObj].
	(self shouldRemapObj: specialObjectsOop) ifTrue:
		[specialObjectsOop := self remapObj: specialObjectsOop].
	"update interpreter variables"
	self
		mapInterpreterOops;
		flushMethodCacheFrom: memStart to: memEnd.
	self remapRemapBufferAndExtraRoots.
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
	<api>
	| header lastFieldOffset action |
	self assert: (self addressCouldBeObjWhileForwarding: oop).
	header := self longAt: oop.
	(header bitAnd: MarkBit) = 0 ifFalse:
		[^ 0  "already marked"].

	"record tracing status in object's header"
	header := (header bitAnd: AllButTypeMask) bitOr: HeaderTypeGC.
	(self oop: oop isGreaterThanOrEqualTo: youngStart) ifTrue:
		[ header := header bitOr: MarkBit ].  "mark only if young"
	self longAt: oop put: header.

	"initialize the tracer state machine"
	parentField := GCTopMarker.
	child := oop.
	lastFieldOffset := self lastPointerOf: oop recordWeakRoot: true.
	field := oop + lastFieldOffset.
	action := StartField.
	youngStartLocal := youngStart.
	statMarkCountLocal := statMarkCount.
	"run the tracer state machine until all objects reachable from oop are marked"
	[action = StartField ifTrue: [ action := self startField ].
	 action = StartObj ifTrue: [ action := self startObj ].
	 action = Upward ifTrue: [ action := self upward ].
	 action = Done] whileFalse.
	statMarkCount := statMarkCountLocal.
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
		((self isIntegerObject: oop) or: [self isFreeObject: oop]) ifFalse:
			[self markAndTrace: oop]].

]

{ #category : #'interpreter access' }
ObjectMemory >> maxCInteger [
	^16rFFFFFFFF
]

{ #category : #'forward compatibility' }
ObjectMemory >> maxIdentityHash [
	^HashMaskUnshifted
]

{ #category : #'interpreter access' }
ObjectMemory >> maxSmallInteger [
	^1073741823
]

{ #category : #'interpreter access' }
ObjectMemory >> maybeSplObj: index [
	<api>
	"Answer one of the objects in the SpecialObjectsArray, if in range, otherwise answer nil."
	^index < (self lengthOf: specialObjectsOop) ifTrue:
		[self fetchPointer: index ofObject: specialObjectsOop]
]

{ #category : #accessing }
ObjectMemory >> memory [
	<cmacro: '() GIV(memory)'>
	^memory
]

{ #category : #accessing }
ObjectMemory >> memory: aValue [
	^memory := aValue
]

{ #category : #'image save/restore' }
ObjectMemory >> memoryBaseForImageRead [
	"Answer the address to read the image into."
	^memory
]

{ #category : #accessing }
ObjectMemory >> memoryLimit [
	^memoryLimit
]

{ #category : #'interpreter access' }
ObjectMemory >> methodDictionaryHash: oop mask: mask [
	<inline: true>
	^mask bitAnd: ((self isImmediate: oop)
						ifTrue: [self integerValueOf: oop]
						ifFalse: [self hashBitsOf: oop])
]

{ #category : #'method access' }
ObjectMemory >> methodHeaderOf: methodObj [
	"Answer the method header of a CompiledMethod object."
	self assert: (self isCompiledMethod: methodObj).
	^self fetchPointer: HeaderIndex ofObject: methodObj
]

{ #category : #allocation }
ObjectMemory >> minSlotsForShortening [
	"HeaderTypeFree free chunks require 1 word of header"
	^1
]

{ #category : #'interpreter access' }
ObjectMemory >> minSmallInteger [
	^-1073741824
]

{ #category : #simulation }
ObjectMemory >> newInputEventAccessorOfSize: numElements [
	<doNotGenerate>
	^CArrayAccessor on: (IntegerArray new: 8)
]

{ #category : #'header access' }
ObjectMemory >> newObjectHash [
	"Answer a new 16-bit pseudo-random number for use as an identity hash."

	lastHash := 13849 + (27181 * lastHash) bitAnd: 65535.
	^ lastHash

]

{ #category : #accessing }
ObjectMemory >> newSpaceSize [
	^freeBlock - self startOfMemory
]

{ #category : #'interpreter access' }
ObjectMemory >> nilObject [
	<api>
	"For access from BitBlt module & Cogit"
	^ nilObj
]

{ #category : #'method access' }
ObjectMemory >> noCheckMethodHeaderOf: methodObj [
	"Answer the method header of a CompiledMethod object."
	^self fetchPointer: HeaderIndex ofObject: methodObj
]

{ #category : #'forward compatibility' }
ObjectMemory >> noFixupFollowField: fieldIndex ofObject: anObject [
	"Spur compatibility; in V3 this is a synonym for fetchPointer:ofObject:"
	<inline: true>
	^self fetchPointer: fieldIndex ofObject: anObject
]

{ #category : #'header access' }
ObjectMemory >> noShiftCompactClassIndexOfHeader: header [
	<api>
	<inline: true>
	^header bitAnd: 16r1F << self compactClassFieldLSB
]

{ #category : #'object format' }
ObjectMemory >> nonWeakFieldsOf: oop [
	"Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length."
	| class classFormat |

	self assert: (self isWeakNonImm: oop).

	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOfNonImm: oop.
	classFormat := self formatOfClass: class.
	^(classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1
]

{ #category : #'garbage collection' }
ObjectMemory >> noteAsRoot: oop headerLoc: headerLoc [ 
	"Record that the given oop in the old object area points to an object in the young area.
	 HeaderLoc is usually = oop, but may be an addr in a forwarding block."
	| header |
	<inline: true>
	header := self longAt: headerLoc.
	(self isYoungRootHeader: header) ifFalse:
		"record oop as root only if not already recorded"
		[rootTableCount < RootTableSize
			ifTrue:
				"record root if there is enough room in the roots table.
				 IMPORTANT: since clearRootsTable is the only thing that clears root bits
				 do *not* set the root bit unless an object is in the root table.  checking
				 routines will complain about the root bit being unset instead of the table
				 being full, but that's life"
				[rootTableCount := rootTableCount + 1.
				 rootTable at: rootTableCount put: oop.
				 self longAt: headerLoc put: (header bitOr: RootBit).
				 rootTableCount >= RootTableRedZone ifTrue:
					"if we're now in the red zone force an IGC ASAP"
					[allocationCount := allocationsBetweenGCs + 1]]
			ifFalse: "note overflow; will need to do a fullGC instead of an incremental."
				[rootTableOverflowed := true]]
]

{ #category : #'object access' }
ObjectMemory >> num16BitUnitsOf: objOop [ 
	"Answer the number of 16-bit units in the given non-immediate object.
	 N..B. Rounds down 8-bit units, so a 5 byte object has 2 16-bit units.
	 Does not adjust the size of contexts by stackPointer."
	^(self numBytesOf: objOop) >> 1
]

{ #category : #'object access' }
ObjectMemory >> num32BitUnitsOf: objOop [ 
	"Answer the number of 16-bit units in the given non-immediate object.
	 N..B. Rounds down 8-bit units, so a 7 byte object has 1 32-bit unit.
	 Does not adjust the size of contexts by stackPointer."
	^(self numBytesOf: objOop) >> 2
]

{ #category : #'object access' }
ObjectMemory >> num64BitUnitsOf: objOop [ 
	"Answer the number of 16-bit units in the given non-immediate object.
	 N..B. Rounds down 8-bit units, so a 15 byte object has 1 64-bit unit.
	 Does not adjust the size of contexts by stackPointer."
	^(self numBytesOf: objOop) >> 3
]

{ #category : #'object access' }
ObjectMemory >> numBytesOf: objOop [ 
	"Answer the number of indexable bytes in the given non-immediate object.
	 Does not adjust the size of contexts by stackPointer."
	<api>
	| header sz fmt |
	header := self baseHeader: objOop.
	sz := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [(self sizeHeader: objOop) bitAnd: AllButTypeMask]
			ifFalse: [header bitAnd: SizeMask].
	fmt := self formatOfHeader: header.
	^fmt < self firstByteFormat
		ifTrue: [(sz - self baseHeaderSize)]  "words"
		ifFalse: [(sz - self baseHeaderSize) - (fmt bitAnd: 3)]  "bytes"
]

{ #category : #'object access' }
ObjectMemory >> numBytesOfBytes: objOop [ 
	"Answer the number of indexable bytes in the given non-immediate byte-indexable object."
	<api>
	| header sz fmt |
	header := self baseHeader: objOop.
	sz := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [(self sizeHeader: objOop) bitAnd: AllButTypeMask]
			ifFalse: [header bitAnd: SizeMask].
	fmt := self formatOfHeader: header.
	self assert: fmt >= self firstByteFormat.
	^(sz - self baseHeaderSize) - (fmt bitAnd: 3)
]

{ #category : #'object access' }
ObjectMemory >> numSlotsOf: obj [
	"Answer the number of oop-sized elements in the given object.
	 Unlike lengthOf: this does not adjust the length of a context
	 by the stackPointer and so can be used e.g. by cloneContext:"
	<api>
	| header sz |
	header := self baseHeader: obj.
	sz := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [(self sizeHeader: obj) bitAnd: AllButTypeMask]
			ifFalse: [header bitAnd: SizeMask].
	^sz - self baseHeaderSize >> self shiftForWord
]

{ #category : #'object access' }
ObjectMemory >> numSlotsOfAny: obj [
	"Sput compatibility"
	^self numSlotsOf: obj
]

{ #category : #'interpreter access' }
ObjectMemory >> numSmallIntegerBits [
	^31
]

{ #category : #'interpreter access' }
ObjectMemory >> numSmallIntegerTagBits [
	^1
]

{ #category : #'object enumeration' }
ObjectMemory >> objectAfter: oop [ 
	"Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete."
	| sz |
	<api>
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
	(header bitAnd: MarkBit) = 0 ifTrue: [ ^ self objectAfter: oop ].  "oop not forwarded"

	"Assume: mark bit cannot be set on a free chunk, so if we get here,
	 oop is not free and it has a forwarding table entry"

	fwdBlock := (header bitAnd: AllButMarkBitAndTypeMask) << 1.
	self assert: (self fwdBlockValid: fwdBlock).
	realHeader := self longAt: fwdBlock + self wordSize.
	"following code is like sizeBitsOf:"
	(realHeader bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ sz := realHeader bitAnd: SizeMask ].

	^ self oopFromChunk: (oop + sz)
]

{ #category : #'object enumeration' }
ObjectMemory >> objectBefore: address [ 
	"Return the object or start of free space immediately preceding the given
	 address, object or free chunk in memory. If none, return 0.  This is for debugging only."
	| obj nextObj sz |
	<api>
	obj := self oopFromChunk: ((self oop: address isGreaterThan: youngStart)
								ifTrue: [youngStart]
								ifFalse: [self startOfMemory]).
	[self oop: obj isLessThan: address] whileTrue:
		[(self isFreeObject: obj)
			ifTrue: [sz := self sizeOfFree: obj]
			ifFalse: [sz := self sizeBitsOf: obj].
		 nextObj := self oopFromChunk: obj + sz.
		 (self oop: nextObj isGreaterThanOrEqualTo: address) ifTrue:
			[^obj].
		 obj := nextObj].
	^0
]

{ #category : #'object enumeration' }
ObjectMemory >> objectExactlyBefore: oop [ 
	"Return the object or start of free space immediately preceding the given
	 object or free chunk in memory. If none, return 0.  This is for debugging only."
	| obj nextObj sz |
	<api>
	obj := self oopFromChunk: ((self oop: oop isGreaterThan: youngStart)
								ifTrue: [youngStart]
								ifFalse: [self startOfMemory]).
	[self oop: obj isLessThan: obj] whileTrue:
		[(self isFreeObject: obj)
			ifTrue: [sz := self sizeOfFree: obj]
			ifFalse: [sz := self sizeBitsOf: obj].
		 nextObj := self oopFromChunk: obj + sz.
		 nextObj = oop ifTrue:
			[^obj].
		 obj := nextObj].
	^0
]

{ #category : #'gc -- compaction' }
ObjectMemory >> objectIsImmutableAndReferencesForwarded: oop [ 
	"Answer if an object is immutable and references a forwarded object.  Used to fail become for immutable referents of becomees."
	"Note: The given oop may be forwarded itself, which means that its real header is in its forwarding table entry."
	| fieldOffset fieldOop |
	<inline: true>
	(self isImmutableWhileForwarding: oop) ifTrue:
		[fieldOffset := self lastPointerWhileForwarding: oop.
		[fieldOffset >= self baseHeaderSize] whileTrue:
			[fieldOop := self longAt: oop + fieldOffset.
			(self isObjectForwarded: fieldOop) ifTrue: [^true].
			 fieldOffset := fieldOffset - self wordSize]].
	^false
]

{ #category : #simulation }
ObjectMemory >> objectMemory [
	<doNotGenerate>
	^self
]

{ #category : #'interpreter access' }
ObjectMemory >> obsoleteDontUseThisFetchWord: fieldIndex ofObject: oop [
	"This message is deprecated but supported for a while via a tweak to sqVirtualMachine.[ch] Use fetchLong32, fetchLong64 or fetchPointer instead for new code"

	^self fetchLong32: fieldIndex ofObject: oop
]

{ #category : #'debug support' }
ObjectMemory >> okayOop: signedOop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class."

	| sz type fmt unusedBit oop |
	<var: #oop type: #usqInt>
	oop := self cCoerce: signedOop to: #usqInt.

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(self oop: oop isGreaterThanOrEqualTo: self startOfMemory andLessThan: endOfMemory)
		ifFalse: [ self error: 'oop is not a valid address'. ^false ].
	((oop \\ self wordSize) = 0)
		ifFalse: [ self error: 'oop is not a word-aligned address'. ^false ].
	sz := self sizeBitsOf: oop.
	(oop + sz) < endOfMemory
		ifFalse: [ self error: 'oop size would make it extend beyond the end of memory'. ^false ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self error: 'oop is a free chunk, not an object'. ^false ].
	type = HeaderTypeShort ifTrue: [
		(self compactClassIndexOf: oop) = 0
			ifTrue:  [ self error: 'cannot have zero compact class field in a short header'. ^false ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= self wordSize) and: [(self headerType: oop - self wordSize) = type])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (self wordSize*2)) and:
		 [(self headerType: oop - (self wordSize*2)) = type and:
		 [(self headerType: oop - self wordSize) = type]])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type'. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	self wordSize = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero'. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	((self isYoungRoot: oop) and: [oop >= youngStart])
		ifTrue: [ self error: 'root bit is set in a young object'. ^false ].
	^true

]

{ #category : #accessing }
ObjectMemory >> oldSpaceSize [
	^youngStart - self startOfMemory
]

{ #category : #'oop/chunk conversion' }
ObjectMemory >> oopFromChunk: chunk [
	"Compute the oop of this chunk by adding its extra header bytes."

	^ chunk + (self extraHeaderBytes: chunk)
]

{ #category : #'image segment in/out' }
ObjectMemory >> oopHasAcceptableClass: signedOop [
	"Similar to oopHasOkayClass:, except that it only returns true or false."

	| oopClass formatMask behaviorFormatBits oopFormatBits oop |
	<var: #oop type: #usqInt>
	<var: #oopClass type: #usqInt>

	(self isIntegerObject: signedOop) ifTrue: [^ true].

	oop := self cCoerce: signedOop to: #usqInt.
	(self addressCouldBeObj: oop) ifFalse: [^ false].

	oopClass := self cCoerce: (self fetchClassOfNonImm: oop) to: #usqInt.
	(self addressCouldBeObj: oopClass) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) < freeBlock ifFalse: [^ false].

	((self isPointersNonImm: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].

	formatMask := (self isBytesNonImm: oop)
						ifTrue: [16rC00]  "ignore extra bytes size bits"
						ifFalse: [16rF00].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
]

{ #category : #'debug support' }
ObjectMemory >> oopHasOkayClass: signedOop [
	"Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance."

	| oop oopClass formatMask behaviorFormatBits oopFormatBits |
	<var: #oop type: #usqInt>
	<var: #oopClass type: #usqInt>

	oop := self cCoerce: signedOop to: #usqInt.
	self okayOop: oop.
	oopClass := self cCoerce: (self fetchClassOf: oop) to: #usqInt.

	(self isIntegerObject: oopClass)
		ifTrue: [ self error: 'a SmallInteger is not a valid class or behavior'. ^false ].
	(self okayOop: oopClass)
		ifFalse: [ self error: 'class oop is not ok'. ^false ].
	((self isPointersNonImm: oopClass) and: [(self lengthOf: oopClass) >= 3])
		ifFalse: [ self error: 'a class (behavior) must be a pointers object of size >= 3'. ^false ].
	(self isBytes: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits
		ifFalse: [ self error: 'object and its class (behavior) formats differ'. ^false ].
	^true
]

{ #category : #'interpreter access' }
ObjectMemory >> popRemappableOop [
	"Pop and return the possibly remapped object from the remap buffer."
	<api>
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

{ #category : #'image save/restore' }
ObjectMemory >> postSnapshot [
	"No op for Spur compatibility."
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
	entriesNeeded := (self lastPointerOf: array1) // self wordSize. "need enough entries for all oops"
	"Note: Forward blocks must be quadword aligned - see fwdTableInit:."
	twoWayFlag
		ifTrue: ["Double the number of blocks for two-way become"
			entriesNeeded := entriesNeeded * 2.
			fwdBlkSize := self wordSize * 2]
		ifFalse: ["One-way become needs backPointers in fwd blocks."
			fwdBlkSize := self wordSize * 4].
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
			oop1 ~= oop2 ifTrue:
				[(self hasForwardingBlock: oop1) ifFalse: "Don't allocate multiple forwarding entries for duplicates."
					[fwdBlock := self fwdBlockGet: fwdBlkSize.
					 self
						initForwardBlock: fwdBlock
						mapping: oop1
						to: oop2
						withBackPtr: twoWayFlag not].
				 (twoWayFlag
				  and: [(self hasForwardingBlock: oop2) not]) ifTrue: "Again don't get confused by duplicates"
					["Second block maps oop2 back to oop1 for two-way become"
							fwdBlock := self fwdBlockGet: fwdBlkSize.
							self
								initForwardBlock: fwdBlock
								mapping: oop2
								to: oop1
								withBackPtr: twoWayFlag not]].
			fieldOffset := fieldOffset - self wordSize].
	^ true
]

{ #category : #'interpreter access' }
ObjectMemory >> primitiveErrorTable [
	<api>
	^self splObj: PrimErrTableIndex
]

{ #category : #'image segment in/out' }
ObjectMemory >> primitiveFailCodeAfterCleanup: outPointerArray [
	"If the storeSegment primitive fails, it must clean up first."

	| i lastAddr |   "Store nils throughout the outPointer array."
	lastAddr := outPointerArray + (self lastPointerOf: outPointerArray).
	i := outPointerArray + self baseHeaderSize.
	[i <= lastAddr] whileTrue:
		[self longAt: i put: nilObj.
		i := i + self wordSize].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^PrimErrGenericFailure
]

{ #category : #'debug printing' }
ObjectMemory >> printActivationsOf: aMethodObj [
	"Scan the heap printing the oops of any and all contexts that refer to anOop"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isContextNonImm: oop)
		  and: [aMethodObj = (self fetchPointer: MethodIndex ofObject: oop)]) ifTrue:
			[self interpreter
				printHex: oop; space; printOopShort: oop; print: ' pc ';
				printHex: (self fetchPointer: InstructionPointerIndex ofObject: oop); cr].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
ObjectMemory >> printContextReferencesTo: anOop [
	"Scan the heap printing the oops of any and all contexts that refer to anOop"
	| oop i |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[(self isContextNonImm: oop) ifTrue:
			[i := CtxtTempFrameStart + (self fetchStackPointerOf: oop)].
			 [(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[self interpreter printHex: oop; print: ' @ '; printNum: i; space; printOopShort: oop; cr.
					 i := 0]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
ObjectMemory >> printInstancesOf: aClassOop [
	"Scan the heap printing the oops of any and all objects that are instances of aClassOop"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[(self fetchClassOfNonImm: oop) = aClassOop ifTrue:
			[self printHex: oop; cr].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
ObjectMemory >> printMethodReferencesTo: anOop [
	"Scan the heap printing the oops of any and all objects that refer to anOop"
	| oop i |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[(self isCompiledMethod: oop) ifTrue:
			[i := (self literalCountOf: oop) + LiteralStart - 1.
			 [i >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[self printHex: oop; print: ' @ '; printNum: i; cr.
					 i := 0].
				 i := i - 1]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
ObjectMemory >> printReferencesTo: anOop [
	"Scan the heap printing the oops of any and all objects that refer to anOop"
	| oop i |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isPointersNonImm: oop) or: [self isCompiledMethod: oop]) ifTrue:
			[(self isCompiledMethod: oop)
				ifTrue:
					[i := (self literalCountOf: oop) + LiteralStart]
				ifFalse:
					[(self isContextNonImm: oop)
						ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop)]
						ifFalse: [i := self lengthOf: oop]].
			[(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[self interpreter printHex: oop; print: ' @ '; printNum: i; space; printOopShort: oop; cr.
					 i := 0]]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
ObjectMemory >> printWronglySizedContexts [
	"Scan the heap printing the oops of any and all contexts whose size is not either SmallContextSize or LargeContextSize"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isContextNonImm: oop)
		   and: [self badContextSize: oop]) ifTrue:
			[self printHex: oop; space; printNum: (self numBytesOf: oop); cr].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'interpreter access' }
ObjectMemory >> pushRemappableOop: oop [
	"Record the given object in a the remap buffer. Objects in this buffer are remapped when a compaction occurs. This facility is used by the interpreter to ensure that objects in temporary variables are properly remapped."
	<api>
	self assert: (self addressCouldBeOop: oop).
	remapBuffer at: (remapBufferCount := remapBufferCount + 1) put: oop.
	remapBufferCount <= RemapBufferSize ifFalse:
		[self error: 'remapBuffer overflow'].
]

{ #category : #'image save/restore' }
ObjectMemory >> readHeapFromImageFile: f dataBytes: numBytes [
	"Read numBytes of image data from f into memory at memoryBaseForImageRead.
	 Answer the number of bytes written."
	<var: #f type: #sqImageFile>
	^self cCode: [
		self cppIf: PharoVM
			ifTrue: [  
				self
					sq: (self pointerForOop: self memoryBaseForImageRead)
					Image: (self sizeof: #char)
					File: numBytes
					ReadEntireImage: f ]
			ifFalse: [ 
				self
					sq: (self pointerForOop: self memoryBaseForImageRead)
					Image: (self sizeof: #char)
					File: numBytes
					Read: f] ]
		inSmalltalk:
			[(f	readInto: memory
				startingAt: self memoryBaseForImageRead // 4 + 1
				count: numBytes // 4)
			 * 4]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remap: oop [
	<api>
	"Map the given oop to its new value during a compaction or 
	become: operation. If it has no forwarding table entry, 
	return the oop itself."
	<inline: false>
	(self isObjectForwarded: oop) ifTrue:
		[^self remappedObj: oop].
	^ oop
]

{ #category : #accessing }
ObjectMemory >> remapBuffer [
	^remapBuffer
]

{ #category : #accessing }
ObjectMemory >> remapBuffer: aValue [
	^remapBuffer := aValue
]

{ #category : #accessing }
ObjectMemory >> remapBufferCount [
	<cmacro: '() GIV(remapBufferCount)'>
	^remapBufferCount
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remapClassOf: oop [ 
	"Update the class of the given object, if necessary, using its forwarding table entry."
	"Note: Compact classes need not be remapped since the compact class field is just an index into the compact class 
	table. The header type bits show if this object has a compact class; we needn't look up the oop's real header."
	| classHeader classOop newClassOop newClassHeader |
	(self headerType: oop) = HeaderTypeShort ifTrue: [^ nil]. "compact classes needn't be mapped"

	classHeader := self longAt: oop - self wordSize.
	classOop := classHeader bitAnd: AllButTypeMask.
	(self isObjectForwarded: classOop) ifTrue:
		[newClassOop := self remappedObj: classOop.
		newClassHeader := newClassOop bitOr: (classHeader bitAnd: TypeMask).
		self longAt: oop - self wordSize put: newClassHeader.
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
	| fieldOffset fieldOop newOop |
	<inline: true>
	fieldOffset := self lastPointerWhileForwarding: oop.
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[fieldOop := self longAt: oop + fieldOffset.
		(self isObjectForwarded: fieldOop) ifTrue:
			["update this oop from its forwarding block"
			newOop := self remappedObj: fieldOop.
			self longAt: oop + fieldOffset put: newOop.
			"The following ensures that become: into old object makes it a root. 
			It does nothing during either incremental or full compaction because 
			oop will never be < youngStart."
			((self oop: oop isLessThan: youngStart)
					and: [self oop: newOop isGreaterThanOrEqualTo: youngStart])
				ifTrue: [self beRootWhileForwarding: oop]].
		fieldOffset := fieldOffset - self wordSize].
	self remapClassOf: oop
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remapObj: obj [
	"Map the given oop to its new value during a compaction or become: operation."
	<inline: false>
	^self remappedObj: obj
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remapRemapBufferAndExtraRoots [
	| oop |
	1 to: remapBufferCount do:
		[:i |
		oop := remapBuffer at: i.
		(self shouldRemapOop: oop) ifTrue:
			[remapBuffer at: i put: (self remapObj: oop)]].
	1 to: extraRootCount do:
		[:i |
		oop := (extraRoots at: i) at: 0.
		((self isIntegerObject: oop) or: [self isFreeObject: oop]) ifFalse:
			[(self shouldRemapObj: oop) ifTrue:
				[(extraRoots at: i) at: 0 put: (self remapObj: oop)]]]
]

{ #category : #'gc -- compaction' }
ObjectMemory >> remappedObj: forwardedObj [
	"Answer the given forwardedOop's target value
	 during a compaction or become: operation."
	| fwdBlock targetObj |
	<inline: true>
	fwdBlock := self forwardingPointerOf: forwardedObj.
	self assert: (self fwdBlockValid: fwdBlock).
	targetObj := self longAt: fwdBlock.
	self assert: (self addressCouldBeObjWhileForwarding: targetObj).
	^targetObj
]

{ #category : #'plugin support' }
ObjectMemory >> removeGCRoot: varLoc [
	"Remove the given variable location to the extra roots table"
	<export: true>
	<var: #varLoc type: #'sqInt *'>
	1 to: extraRootCount do:
		[:i|
		varLoc = (extraRoots at: i) ifTrue: "swap varLoc with last entry"
			[extraRoots at: i put: (extraRoots at: extraRootCount).
			 extraRootCount := extraRootCount-1.
			 ^true]].
	^false "not found"
]

{ #category : #become }
ObjectMemory >> removeYoungRoot: obj [
	"Remove the given young root from the root table (for freeObject: for becomeForward:)."
	<inline: false>
	1 to: rootTableCount do:
		[:i|
		obj = (rootTable at: i) ifTrue:"swap obj with last entry"
			[rootTable at: i put: (rootTable at: rootTableCount).
			rootTableCount := rootTableCount - 1.
			^true]].
	^false "not found"
]

{ #category : #become }
ObjectMemory >> restoreHeaderOf: obj [
	"Restore the original header of the given obj from its forwarding block."
	<inline: true> "for subclasses"
	| fwdHeader fwdBlock objHeader |
	fwdHeader := self longAt: obj.
	fwdBlock := (fwdHeader bitAnd: AllButMarkBitAndTypeMask) << 1.
	self assert: (fwdHeader bitAnd: MarkBit) ~= 0.
	self assert: (self fwdBlockValid: fwdBlock).
	objHeader := self longAt: fwdBlock + self wordSize.
	self restoreHeaderOf: obj to: objHeader
]

{ #category : #become }
ObjectMemory >> restoreHeaderOf: obj to: objHeader [
	"helper for restoreHeaderOf: for subclasses to override"
	<inline: true> "for subclasses"
	self longAt: obj put: objHeader
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
						put: ((hdr1 bitAnd: AllButHashBits) bitOr: (hdr2 bitAnd: HashBits)).
					self
						longAt: oop2
						put: ((hdr2 bitAnd: AllButHashBits) bitOr: (hdr1 bitAnd: HashBits))].
			fieldOffset := fieldOffset - self wordSize]
]

{ #category : #become }
ObjectMemory >> restoreHeadersAfterForwardBecome: copyHashFlag [
	"Forward become leaves us with no original oops in the
	 mutated object list, so we must enumerate the (four-word)
	 forwarding blocks where we have stored backpointers."
	"This loop start is copied from fwdTableInit:"
	| oop1 fwdBlock oop2 hdr1 hdr2 |
	fwdBlock := endOfMemory + self baseHeaderSize + 7 bitAnd: WordMask - 7.
	self flag: #Dan.  "See flag comment in fwdTableInit: (dtl)"
	fwdBlock := fwdBlock + (self wordSize*4).
	"fwdBlockGet: did a pre-increment"
	[self oop: fwdBlock isLessThanOrEqualTo: fwdTableNext
	"fwdTableNext points to the last active block"]
		whileTrue:
			[oop1 := self longAt: fwdBlock + (self wordSize*2).
			"Backpointer to mutated object."
			oop2 := self longAt: fwdBlock.
			self restoreHeaderOf: oop1.
			copyHashFlag ifTrue:
				"Change the hash of the new oop (oop2) to be that of the old (oop1)
				 so mutated objects in hash structures will be  happy after the change."
				[hdr1 := self longAt: oop1.
				 hdr2 := self longAt: oop2.
				 self longAt: oop2 put: ((hdr2 bitAnd: AllButHashBits) bitOr: (hdr1 bitAnd: HashBits))].
			"Free the old object so it won't resurface through e.g. alInstances or allObjects."
			self freeObject: oop1.
			fwdBlock := fwdBlock + (self wordSize*4)]
]

{ #category : #'image segment in/out' }
ObjectMemory >> restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut [

	"Restore headers smashed by forwarding links"
	| tablePtr oop header |
	tablePtr := firstIn.
	[self oop: tablePtr isLessThanOrEqualTo: lastIn] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseIn + (tablePtr-firstIn).
		self longAt: oop put: header.
		tablePtr := tablePtr + self wordSize].
	tablePtr := firstOut.
	[self oop: tablePtr isLessThanOrEqualTo: lastOut] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr := tablePtr + self wordSize].
	
	"Clear all mark bits"
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self longAt: oop put: ((self longAt: oop) bitAnd: AllButMarkBit)].
		oop := self objectAfter: oop]
]

{ #category : #'image save/restore' }
ObjectMemory >> reverseBytesFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr := addr + self wordSize].
]

{ #category : #'image save/restore' }
ObjectMemory >> reverseWordsFrom: startAddr to: stopAddr [
	"Word-swap the given range of memory, excluding stopAddr."

	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self wordSwapped: (self longAt: addr)).
		addr := addr + self wordSize].
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

{ #category : #accessing }
ObjectMemory >> rootTable [
	^rootTable
]

{ #category : #'interpreter access' }
ObjectMemory >> rootTableCapacity [
	^RootTableSize
]

{ #category : #accessing }
ObjectMemory >> rootTableCount [
	^rootTableCount
]

{ #category : #accessing }
ObjectMemory >> rootTableCount: aValue [
	^rootTableCount := aValue
]

{ #category : #'primitive support' }
ObjectMemory >> rootTableObject [
	"Answer an object containing the contents of the rootTable for primitiveRootTable.
	 The allocation can cause a GC itself and if so the return value may be inaccurate
	 - in this case one should guard the read operation by looking at the gc counter statistics."
	| tableObj sz j |
	sz := rootTableCount.
	tableObj := self instantiateClass: self classArray indexableSize: sz. "can cause GC (and hence reduce number of roots)"
	j := 0.
	1 to: rootTableCount do:
		[:i| "By definition the roots are old and being new, tableObj is young so there is no need to store check."
		self storePointerUnchecked: j ofObject: tableObj withValue: (rootTable at: i)].
	rootTableCount < sz ifTrue:
		[self shorten: tableObj toIndexableSize: rootTableCount].
	^tableObj
]

{ #category : #'debug printing' }
ObjectMemory >> safePrintStringOf: oop [
	"Version of printStringOf: that copes with forwarding during garbage collection."
	| fmt header cnt i |
	<inline: false>
	(self isIntegerObject: oop) ifTrue:
		[^nil].
	(self oop: oop isGreaterThanOrEqualTo: self startOfMemory andLessThan: freeBlock) ifFalse:
		[^nil].
	(oop bitAnd: (self wordSize - 1)) ~= 0 ifTrue:
		[^nil].
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt < self firstByteFormat ifTrue: [^nil].

	cnt := 100 min: (self lengthOf: oop baseHeader: header format: fmt).
	i := 0.

	[i < cnt] whileTrue:
		[self printChar: (self fetchByte: i ofObject: oop).
		 i := i + 1].
	self flush.
	^oop
]

{ #category : #initialization }
ObjectMemory >> setEndOfMemory: newEndOfMemory [
	self assert: (newEndOfMemory bitAnd: self wordSize - 1) = 0.
	endOfMemory := newEndOfMemory
]

{ #category : #'header access' }
ObjectMemory >> setHashBitsOf: oop to: hash [
	self longAt: oop
		put: (((self baseHeader: oop) bitClear: HashBits)
				bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset)
]

{ #category : #initialization }
ObjectMemory >> setHeapBase: baseOfHeap memoryLimit: memLimit endOfMemory: memEnd [
	"Set the dimensions of the heap, answering the start of oldSpace."
	self setMemoryLimit: memLimit.
	self setEndOfMemory: memEnd.
	^baseOfHeap
]

{ #category : #'header access' }
ObjectMemory >> setIsMarkedOf: objOop to: aBoolean [
	| header |
	self assert: (self isFreeObject: objOop) not.
	header := self baseHeader: objOop.
	self
		baseHeader: objOop
		put: (aBoolean
				ifTrue: [header bitOr: MarkBit]
				ifFalse: [(header bitOr: MarkBit) - MarkBit])
]

{ #category : #initialization }
ObjectMemory >> setMemoryLimit: newMemoryLimit [
	self assert: (newMemoryLimit bitAnd: self wordSize - 1) = 0.
	memoryLimit := newMemoryLimit
]

{ #category : #'header access' }
ObjectMemory >> setSizeOfFree: chunk to: byteSize [
	"Set the header of the given chunk to make it be a free chunk of the given size."

	self longAt: chunk put: ((byteSize bitAnd: AllButTypeMask) bitOr: HeaderTypeFree).
]

{ #category : #'interpreter access' }
ObjectMemory >> shiftForWord [
	"N.B. This would appear to hard-code the header size for 32-bit images.  But if generating
	 a 64-bit image, this method could be removed and the relevant one substituted.  We can't
	 mark this method as <doNotGenerate> as we need an actual method to guide code gen."
	<api>
	<cmacro>
	^2
]

{ #category : #allocation }
ObjectMemory >> shorten: obj toIndexableSize: nSlots [
	"Reduce the number of indexable fields in obj, a pointer object, to nSlots. Convert the
	unused residual to a free chunk. Word and byte indexable objects are not changed.
	Answer the number of bytes returned to free memory, which may be zero if no change
	was possible."
	| deltaBytes desiredLength fixedFields fmt hdr totalLength
	 indexableFields |
	(self isPointersNonImm: obj) ifFalse: [^0].
	nSlots >  0
		ifFalse: [^0]. "no change if nSlots is zero, error if nSlots is negative"
	hdr := self baseHeader: obj.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: obj baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: obj format: fmt length: totalLength.
	indexableFields := totalLength - fixedFields.
	nSlots >= indexableFields
		ifTrue: [^0]. "no change, or error if attempting to increase size into next chunk"
	desiredLength := fixedFields + nSlots.		
	deltaBytes := (totalLength - desiredLength) * self wordSize.
	self setSizeOfFree: obj + self baseHeaderSize + (desiredLength * self wordSize)
		to: deltaBytes.
	(self headerType: obj) caseOf:	{
		[HeaderTypeSizeAndClass] ->
			[self longAt: (obj - (self baseHeaderSize * 2)) put: (self sizeHeader: obj) - deltaBytes].
		[HeaderTypeClass] ->
			[self longAt: obj put: ((hdr bitClear: SizeMask) bitOr: (hdr bitAnd: SizeMask) - deltaBytes)].
		[HeaderTypeShort] ->
			[self longAt: obj put: ((hdr bitClear: SizeMask) bitOr: (hdr bitAnd: SizeMask) - deltaBytes)] }.
	^deltaBytes
]

{ #category : #'gc -- compaction' }
ObjectMemory >> shouldRemapObj: oop [
	<api>
	"Answer if the oop should be remapped"
	<inline: true>
	^self isObjectForwarded: oop
]

{ #category : #'gc -- compaction' }
ObjectMemory >> shouldRemapOop: oop [
	<api>
	"Answer if the oop should be remapped"
	<inline: true>
	^(self isNonIntegerObject: oop)
	  and: [self isObjectForwarded: oop]
]

{ #category : #allocation }
ObjectMemory >> shrinkObjectMemory: delta [ 
	"Attempt to shrink the object memory by the given delta 
	amount "
	| limit |
	statShrinkMemory := statShrinkMemory + 1. 
	limit := self sqShrinkMemory: memoryLimit By: delta.
	limit = memoryLimit ifFalse:
		[self setMemoryLimit: limit - 24. "remove a tad for safety"
		 self initializeMemoryFirstFree: freeBlock]
]

{ #category : #accessing }
ObjectMemory >> shrinkThreshold [
	^shrinkThreshold
]

{ #category : #accessing }
ObjectMemory >> shrinkThreshold: aValue [
	^shrinkThreshold := aValue
]

{ #category : #accessing }
ObjectMemory >> signalLowSpace [
	^signalLowSpace
]

{ #category : #accessing }
ObjectMemory >> signalLowSpace: aValue [
	^signalLowSpace := aValue
]

{ #category : #'header formats' }
ObjectMemory >> sixtyFourBitIndexableFormat [
	^7
]

{ #category : #'object access' }
ObjectMemory >> sizeBitsOf: oop [
	"Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words."
	"Note: byte indexable objects need to have low bits subtracted from this size."

	| header |
	header := self baseHeader: oop.
	(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ ^ header bitAnd: SizeMask ].
]

{ #category : #'object access' }
ObjectMemory >> sizeBitsOfSafe: oop [
	"Compute the size of the given object from the cc and size fields in its header. This works even if its type bits are not correct."

	| header type |
	header := self baseHeader: oop.
	type := self rightType: header.
	type = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: AllButTypeMask ]
		ifFalse: [ ^ header bitAnd: SizeMask ].
]

{ #category : #'header access' }
ObjectMemory >> sizeHeader: oop [

	^ self longAt: oop - (self wordSize*2)
]

{ #category : #'header access' }
ObjectMemory >> sizeOfFree: oop [
	"Return the size of the given chunk in bytes. Argument MUST be a free chunk."

	^ (self longAt: oop) bitAnd: AllButTypeMask
]

{ #category : #'object access' }
ObjectMemory >> slotSizeOf: oop [
	"Returns the number of slots in the receiver.
	If the receiver is a byte object, return the number of bytes.
	Otherwise return the number of words."
	(self isIntegerObject: oop) ifTrue:[^0].
	^self lengthOf: oop
]

{ #category : #'cog jit support' }
ObjectMemory >> specialObjectsOop [
	^specialObjectsOop
]

{ #category : #'cog jit support' }
ObjectMemory >> specialObjectsOop: anObject [
	specialObjectsOop := anObject
]

{ #category : #accessing }
ObjectMemory >> splObj: index [
	<api>
	<inline: true>
	"Return one of the objects in the SpecialObjectsArray"
	^self fetchPointer: index ofObject: specialObjectsOop
]

{ #category : #'interpreter access' }
ObjectMemory >> splObj: index put: anObject [
	"Set one of the objects in the SpecialObjectsArray"
	self storePointer: index ofObject: specialObjectsOop withValue: anObject
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> startField [
	"Examine and possibly trace the next field of the object being
	 traced. See comment in markAndTrace for explanation of
	 tracer state variables, and aComment for gory details."
	| typeBits childType |
	<inline: true>
	[child := self longAt: field.
	 self isIntegerObject: child] whileTrue:
		["field contains a SmallInteger; skip it"
		field := field - self wordSize.
		"Effectively ^ StartField"].
	typeBits := child bitAnd: TypeMask.
	typeBits = 0 ifTrue: "normal oop, go down"
		[self longAt: field put: parentField.
		parentField := field.
		^ StartObj].
	self assert: typeBits = 2.
	"reached the header; do we need to process the class word? "
	(child bitAnd: CompactClassMask) ~= 0 ifTrue:
		["object's class is compact; we're done"
		"restore the header type bits"
		child := child bitAnd: AllButTypeMask.
		childType := self rightType: child.
		self longAt: field put: (child bitOr: childType).
		^ Upward].
	"object has a full class word; process that class"
	child := self longAt: field - self wordSize. "class word"
	child := child bitAnd: AllButTypeMask. "clear type bits"
	self longAt: field - self wordSize put: parentField.
	parentField := field - self wordSize bitOr: 1.
	"point at class word; mark as working on the class. "
	^ StartObj
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> startObj [
	"Start tracing the object 'child' and answer the next action. 
	 The object may be anywhere in the middle of being swept 
	 itself. See comment in markAndTrace for explanation of 
	 tracer state variables, and aComment for gory details."
	| header lastFieldOffset |
	<inline: true>
	statMarkCountLocal := statMarkCountLocal + 1.
	((self oop: child isLessThan: youngStartLocal) "old object; skip it"
	 or: [((header := self longAt: child) bitAnd: MarkBit) ~= 0]) "already marked; skip it"
		ifTrue:
			[field := child.
			^ Upward].
	"unmarked; mark and trace"
	lastFieldOffset := self lastPointerOf: child recordWeakRoot: false.
	header := (header bitAnd: AllButTypeMask) bitOr: (MarkBit bitOr: HeaderTypeGC).
	self longAt: child put: header.
	field := child + lastFieldOffset.
	^ StartField "trace its fields and class"
]

{ #category : #'memory access' }
ObjectMemory >> startOfFreeSpace [
	<inline: true>
	^freeBlock
]

{ #category : #'object enumeration' }
ObjectMemory >> startOfMemory [
	"Return the start of object memory. Use a macro so as not to punish the debug VM."
	<cmacro: '() GIV(memory)'>
	<returnTypeC: #usqInt>
	^memory
]

{ #category : #accessing }
ObjectMemory >> statCompMoveCount [
	^statCompMoveCount
]

{ #category : #accessing }
ObjectMemory >> statFullGCUsecs [
	^statFullGCUsecs
]

{ #category : #accessing }
ObjectMemory >> statFullGCs [
	^statFullGCs
]

{ #category : #accessing }
ObjectMemory >> statGrowMemory [
	^statGrowMemory
]

{ #category : #accessing }
ObjectMemory >> statIGCDeltaUsecs [
	^statIGCDeltaUsecs
]

{ #category : #accessing }
ObjectMemory >> statIncrGCUsecs [
	^statIncrGCUsecs
]

{ #category : #accessing }
ObjectMemory >> statIncrGCs [
	^statIncrGCs
]

{ #category : #accessing }
ObjectMemory >> statMarkCount [
	^statMarkCount
]

{ #category : #accessing }
ObjectMemory >> statMkFwdCount [
	^statMkFwdCount
]

{ #category : #accessing }
ObjectMemory >> statNumGCs [
	^statIncrGCs + statFullGCs
]

{ #category : #accessing }
ObjectMemory >> statRootTableCount [
	^statRootTableCount
]

{ #category : #accessing }
ObjectMemory >> statRootTableOverflows [
	^statRootTableOverflows
]

{ #category : #accessing }
ObjectMemory >> statShrinkMemory [
	^statShrinkMemory
]

{ #category : #accessing }
ObjectMemory >> statSpecialMarkCount [
	^statSpecialMarkCount
]

{ #category : #accessing }
ObjectMemory >> statSurvivorCount [
	^statSurvivorCount
]

{ #category : #accessing }
ObjectMemory >> statSweepCount [
	^statSweepCount
]

{ #category : #accessing }
ObjectMemory >> statTenures [
	^statTenures
]

{ #category : #'object access' }
ObjectMemory >> storeByte: byteIndex ofObject: oop withValue: valueByte [

	^ self byteAt: oop + self baseHeaderSize + byteIndex
		put: valueByte
]

{ #category : #'image segment in/out' }
ObjectMemory >> storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots [

"This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set."

"The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded."

	| savedYoungStart lastOut lastIn firstIn lastSeg endSeg segOop fieldPtr fieldOop mapOop
	  doingClass lastPtr extraSize hdrTypeBits hdrBaseIn hdrBaseOut header firstOut versionOffset |
	<inline: false>
	<var: #firstIn type: #usqInt>
	<var: #lastIn type: #usqInt>
	<var: #firstOut type: #usqInt>
	<var: #lastOut type: #usqInt>
	<var: #hdrBaseIn type: #usqInt>
	<var: #hdrBaseOut type: #usqInt>
	<var: #lastSeg type: #usqInt>
	<var: #endSeg type: #usqInt>
	<var: #fieldPtr type: #usqInt>
	<var: #lastPtr type: #usqInt>
	<var: #segOop type: #usqInt>
	<var: #savedYoungStart type: #usqInt>

	((self headerType: outPointerArray) = HeaderTypeSizeAndClass			"Must be 3-word header"
	and: [(self headerType: segmentWordArray) = HeaderTypeSizeAndClass])	"Must be 3-word header"
		ifFalse: [^PrimErrGenericFailure].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	"Use the top half of outPointers for saved headers."
	firstOut := outPointerArray + self baseHeaderSize.
	lastOut := firstOut - self wordSize.
	hdrBaseOut := outPointerArray + ((self lastPointerOf: outPointerArray) // (self wordSize*2) * self wordSize). "top half"

	lastSeg := segmentWordArray.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - self wordSize.

	"Write a version number for byte order and version check"
	versionOffset := self wordSize.
	lastSeg := lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^PrimErrGenericFailure].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn := endSeg - ((self sizeBitsOf: segmentWordArray) // (self wordSize*8) * self wordSize).  "Take 1/8 of seg"
	lastIn := firstIn - self wordSize.
	hdrBaseIn := firstIn + ((self sizeBitsOf: segmentWordArray) // (self wordSize*16) * self wordSize). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: MarkBit).
	lastPtr := arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr := arrayOfRoots + self baseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: MarkBit)].
		fieldPtr := fieldPtr + self wordSize].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart := youngStart.
	youngStart := self startOfMemory.  "process all of memory"
	self markAndTraceInterpreterOops.	"and special objects array"
	youngStart := savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: AllButMarkBit).
	fieldPtr := arrayOfRoots + self baseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: AllButMarkBit)].
		fieldPtr := fieldPtr + self wordSize].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn := lastIn + self wordSize.
	(lastIn >= hdrBaseIn
	 or: [0 = (lastSeg := self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
		[lastIn := lastIn - self wordSize.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^self primitiveFailCodeAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop := self oopFromChunk: segmentWordArray + versionOffset + self baseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr := segOop - self wordSize.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + self baseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits := fieldOop bitAnd: TypeMask.
				fieldOop := fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue: ["Just an integer -- nothing to do"
						fieldPtr := fieldPtr + self wordSize]
				ifFalse:
				[header := self longAt: fieldOop.
				(header bitAnd: TypeMask) = HeaderTypeFree
					ifTrue: ["Has already been forwarded -- this is the link"
							mapOop := header bitAnd: AllButTypeMask]
					ifFalse:
					[((self longAt: fieldOop) bitAnd: MarkBit) = 0
						ifTrue:
							["Points to an unmarked obj -- an internal pointer.
							Copy the object into the segment, and forward its oop."
							lastIn := lastIn + self wordSize.
							(lastIn >= hdrBaseIn
							or: [0 = (lastSeg := self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
								["Out of space in segment"
								lastIn := lastIn - self wordSize.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
							mapOop := (self longAt: fieldOop) bitAnd: AllButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut := lastOut + self wordSize.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut := lastOut - self wordSize.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
.							mapOop := lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + (self wordSize*2).
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + self wordSize]]].
		segOop := self objectAfter: segOop].

	self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.

	"Truncate the outPointerArray..."
	((outPointerArray + (self lastPointerOf: outPointerArray) - lastOut) < 12
		or: [(endSeg - lastSeg) < 12]) ifTrue:
			["Not enough room to insert simple 3-word headers"
			^self primitiveFailCodeAfterCleanup: outPointerArray].
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastOut+self wordSize.
	"Adjust the size of the original as well as the free chunk."
	self longAt: lastOut+self wordSize
		put: outPointerArray + (self lastPointerOf: outPointerArray) - lastOut - extraSize + hdrTypeBits.
	self longAt: outPointerArray-extraSize
		put: lastOut - firstOut + (self wordSize*2) + hdrTypeBits.
	"Note that pointers have been stored into roots table"
	self beRootIfOld: outPointerArray.

	"Truncate the image segment..."
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastSeg+self wordSize.
	"Adjust the size of the original as well as the free chunk."
	self longAt: segmentWordArray-extraSize
		put: lastSeg - segmentWordArray + self baseHeaderSize + hdrTypeBits.
	self longAt: lastSeg+self wordSize
		put: endSeg - lastSeg - extraSize + hdrTypeBits.

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^PrimNoErr
]

{ #category : #'object access' }
ObjectMemory >> storeLong32: fieldIndex ofObject: oop withValue: valueWord [

	^ self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
		put: valueWord
]

{ #category : #'object access' }
ObjectMemory >> storeLong64: longIndex ofObject: oop withValue: value [
	<var: #value type: #sqLong>
	self flag: #endianness.
	self long32At: oop + self baseHeaderSize + (longIndex << 3) put: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFFFFFFFF]);
		long32At: oop + self baseHeaderSize + (longIndex << 3) + 4 put: (value >> 32).
	^value
]

{ #category : #'object access' }
ObjectMemory >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."

	(self oop: oop isLessThan: youngStart) ifTrue: [
		self possibleRootStoreInto: oop value: valuePointer.
	].

	^ self longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
ObjectMemory >> storePointerImmutabilityCheck: index ofObject: rcvr withValue: top [
	<inline: true>
	^ self storePointer: index ofObject: rcvr withValue: top
]

{ #category : #'object access' }
ObjectMemory >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	"Like storePointer:ofObject:withValue:, but the caller guarantees that the
	 object being stored into is a young object or is already marked as a root."
	<api>
	<inline: true>
	^self
		longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
ObjectMemory >> storeShort16: shortIndex ofObject: objOop withValue: value [
	^self
		shortAt: objOop + self baseHeaderSize + (shortIndex << 1)
		put: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFFFF])
]

{ #category : #'interpreter access' }
ObjectMemory >> storeWord: fieldIndex ofObject: oop withValue: valueWord [
	"This message is deprecated.  Use storeLong32, storeLong64 or storePointer"

	self abort
]

{ #category : #'primitive support' }
ObjectMemory >> stringForCString: aCString [
	"Answer a new String copied from a null-terminated C string,
	 or nil if out of memory.
	 Caution: This may invoke the garbage collector."
	<api>
	<var: 'aCString' type: 'const char *'>
	<inline: false>
	| len newString |
	len := self strlen: aCString.
	newString := self instantiateClass: (self splObj: ClassByteString) indexableSize: len.
	newString ifNotNil:
		[self st: (self cCoerceSimple: newString + self baseHeaderSize to: #'char *')
			rn: aCString
			cpy: len]. "(char *)strncpy()"
	^newString
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceAfterGC: minFree [ 
	"Return true if there is enough free space after doing a garbage collection. If not, signal that space is low."
	| growSize |
	<inline: false>

	self incrementalGC. "try to recover some space"

	(self oop: (self sizeOfFree: freeBlock) isLessThan: minFree)
		ifTrue: [signalLowSpace ifTrue: [^false]. "give up; problem is already noted"
			self fullGC. "try harder"
			"for stability, require more free space after doing an expensive full GC"
			(self cCoerce: (self sizeOfFree: freeBlock) to: 'usqInt ') >= ((self cCoerce: minFree to: 'usqInt ') + 15000) ifTrue: [^ true].

			"still not enough; attempt to grow object memory"
			growSize := minFree - (self sizeOfFree: freeBlock) + growHeadroom.
			self growObjectMemory: growSize.

			(self oop: (self sizeOfFree: freeBlock) isGreaterThanOrEqualTo: minFree + 15000)
				ifTrue: [^true].

			"still not enough"
			^false].
	^true
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceToAllocate: bytes [
	"Return true if there is enough space to allocate the given number of bytes, perhaps after doing a garbage collection."

	| minFree |
	<inline: true>
	minFree := (lowSpaceThreshold + bytes + self baseHeaderSize + self wordSize - 1) bitClear: self wordSize - 1.

	"check for low-space"
	(self oop: (self sizeOfFree: freeBlock) isGreaterThanOrEqualTo: minFree)
		ifTrue: [^true]
		ifFalse: [^self sufficientSpaceAfterGC: minFree].
]

{ #category : #allocation }
ObjectMemory >> sufficientSpaceToInstantiate: classOop indexableSize: size [ 
	"Return the number of bytes required to allocate an instance of the given class with the given number of indexable fields."
	"Details: For speed, over-estimate space needed for fixed fields or literals; the low space threshold is a blurry line."
	<var: #size type: #usqInt>
	| format allocSize |
	<inline: true>
	(format := self instSpecOfClass: classOop) < self firstByteFormat
		ifTrue:
			["indexable fields are words or pointers"
			size ~= 0 ifTrue:
				["fail if attempting to call new: on non-indexable class"
				 format < self arrayFormat ifTrue:
					[^false].
				 "fail if attempting to allocate over 2 Gb, since this overflows 32-bit arithmetic"
				 size >> (LongSizeNumBits - self shiftForWord) > 0 ifTrue:
					[^false]].
			allocSize := size * self wordSize]
		ifFalse:
			["indexable fields are bytes"
			 "fail if attempting to allocate over 2 Gb, since this overflows 32-bit arithmetic"
			 size >> LongSizeNumBits > 0 ifTrue:
				[^false].
			allocSize := size].
	^self sufficientSpaceToAllocate: 2500 + allocSize
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
	entriesAvailable := self fwdTableInit: self wordSize*2.
	survivors := 0.
	freeChunk := nil.
	firstFree := nil.
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
				ifTrue: [oopSize := oopHeader bitAnd: SizeMask]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize := (self sizeHeader: oop) bitAnd: LongSizeMask]
						ifFalse: ["free chunk" oopSize := oopHeader bitAnd: LongSizeMask]].
			(oopHeader bitAnd: MarkBit) = 0
				ifTrue: ["object is not marked; free it"
					"<-- Finalization support: We need to mark each oop chunk as free -->"
					self longAt: oop - hdrBytes put: HeaderTypeFree.
					freeChunk ~= nil
						ifTrue: ["enlarge current free chunk to include this oop"
							freeChunkSize := freeChunkSize + oopSize + hdrBytes]
						ifFalse: ["start a new free chunk"
							freeChunk := oop - hdrBytes.
							"chunk may start 4 or 8 bytes before oop"
							freeChunkSize := oopSize + (oop - freeChunk).
							"adjust size for possible extra header bytes"
							firstFree = nil ifTrue: [firstFree := freeChunk]]]
				ifFalse: ["object is marked; clear its mark bit and possibly adjust 
					the compaction start"
					self longAt: oop put: (oopHeader bitAnd: AllButMarkBit).
					"<-- Finalization support: Check if we're running about a weak class -->"
					(self isWeakNonImm: oop) ifTrue: [self finalizeReference: oop].
					entriesAvailable > 0
						ifTrue: [entriesAvailable := entriesAvailable - 1]
						ifFalse: ["start compaction at the last free chunk before this object"
							firstFree := freeChunk].
					freeChunk ~= nil
						ifTrue: ["record the size of the last free chunk"
							self longAt: freeChunk put: ((freeChunkSize bitAnd: LongSizeMask) bitOr: HeaderTypeFree).
							freeChunk := nil].
					survivors := survivors + 1].
			oop := self oopFromChunk: oop + oopSize].
	freeChunk ~= nil
		ifTrue: ["record size of final free chunk"
			self longAt: freeChunk put: ((freeChunkSize bitAnd: LongSizeMask) bitOr: HeaderTypeFree)].
	oop = endOfMemory
		ifFalse: [self error: 'sweep failed to find exact end of memory'].
	firstFree = nil
		ifTrue: [self error: 'expected to find at least one free object']
		ifFalse: [compStart := firstFree].

	^ survivors
]

{ #category : #'garbage collection' }
ObjectMemory >> tenuringIncrementalGC [
	"Do an incremental GC that tenures all surviving young objects to old space."
	<api>
	forceTenureFlag := true.
	self incrementalGC
]

{ #category : #accessing }
ObjectMemory >> tenuringThreshold [
	^tenuringThreshold
]

{ #category : #accessing }
ObjectMemory >> tenuringThreshold: aValue [
	^tenuringThreshold := aValue
]

{ #category : #'interpreter access' }
ObjectMemory >> topRemappableOop [
	<api>
	"Returns the top of the remappable oop. Useful when writing loops."
	^remapBuffer at: remapBufferCount
]

{ #category : #accessing }
ObjectMemory >> totalMemorySize [
	^endOfMemory - self startOfMemory
]

{ #category : #utilities }
ObjectMemory >> transfer: count from: src to: dst [ 
	| in out lastIn |
	<inline: true>
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	in := src - self wordSize.
	lastIn := in + (count * self wordSize).
	out := dst - self wordSize.
	[self oop: in isLessThan: lastIn]
		whileTrue: [self
				longAt: (out := out + self wordSize)
				put: (self longAt: (in := in + self wordSize))]
]

{ #category : #'plugin support' }
ObjectMemory >> trueObject [
	<api>
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
	NOTE: Type field of object below has already been restored!!!
	 See comment in markAndTrace for explanation of 
	 tracer state variables, and aComment for gory details."
	| type header |
	<inline: true>
	[(parentField bitAnd: 1) = 0 ifTrue:
		["normal"
		child := field. "who we worked on below"
		field := parentField. "where to put it"
		parentField := self longAt: field.
		self longAt: field put: child.
		field := field - self wordSize. "point at header"
		^ StartField].
	 parentField = GCTopMarker ifTrue:
		["top of the chain"
		header := (self longAt: field) bitAnd: AllButTypeMask.
		type := self rightType: header.
		self longAt: field put: (header bitOr: type). "install type on class oop"
		^ Done].
	"was working on the extended class word"
	child := field. "oop of class"
	field := parentField - 1. "class word, ** clear the low bit **"
	parentField := self longAt: field.
	header := self longAt: field + self wordSize. "base header word"
	type := self rightType: header.
	self longAt: field put: (child bitOr: type). "install type on class oop"
	field := field + self wordSize. "point at header"
	"restore type bits"
	header := header bitAnd: AllButTypeMask.
	self longAt: field put: (header bitOr: type).
	"Effectively ^ Upward"
	true] whileTrue.
	^nil "for Slang..."
]

{ #category : #simulation }
ObjectMemory >> validate [
	"Validate all the objects in the heap."
	self cCode: [] inSmalltalk: [
	| oop prev |
	self interpreter transcript show: 'Validating...'.
	oop := self firstObject.
	[oop < endOfMemory] whileTrue: [
		self validate: oop.
		prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop.
	].
	self touch: prev.  "Don't offer to delete this please"
	self interpreter transcript show: 'done.'; cr]
]

{ #category : #simulation }
ObjectMemory >> validate: oop [
	<doNotGenerate>
	| header type cc sz fmt nextChunk | 
	header := self longAt: oop.
	type := header bitAnd: 3.
	type = 2 ifFalse: [type = (self rightType: header) ifFalse: [self halt]].
	sz := (header bitAnd: SizeMask) >> 2.
	(self isFreeObject: oop)
		ifTrue: [ nextChunk := oop + (self sizeOfFree: oop) ]
		ifFalse: [  nextChunk := oop + (self sizeBitsOf: oop) ].
	nextChunk > endOfMemory
		ifTrue: [oop = endOfMemory ifFalse: [self halt]].
	(self headerType: nextChunk) = 0 ifTrue: [
		(self headerType: (nextChunk + (self wordSize*2))) = 0 ifFalse: [self halt]].
	(self headerType: nextChunk) = 1 ifTrue: [
		(self headerType: (nextChunk + self wordSize)) = 1 ifFalse: [self halt]].
	type = 2 ifTrue:
		["free block" ^ self].
	fmt := self formatOfHeader: header.
	cc := self compactClassIndexOfHeader: header.
	cc > 16 ifTrue: [self halt].	"up to 32 are legal, but not used"
	type = 0 ifTrue:
		["three-word header"
		((self longAt: oop-self wordSize) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-(self wordSize*2)) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-self wordSize) = type) ifTrue: [self halt].	"Class word is 0"
		sz = 0 ifFalse: [self halt]].
	type = 1 ifTrue:
		["two-word header"
		((self longAt: oop-self wordSize) bitAnd: 3) = type ifFalse: [self halt].
		cc > 0 ifTrue: [sz = 1 ifFalse: [self halt]].
		sz = 0 ifTrue: [self halt]].
	type = 3 ifTrue:
		["one-word header"
		cc = 0 ifTrue: [self halt]].
	fmt = 5 ifTrue: [self halt].
	fmt = 7 ifTrue: [self halt].
	fmt >= self firstCompiledMethodFormat ifTrue: "must have integer header"
		[(self isIntegerObject: (self longAt: oop + self wordSize)) ifFalse: [self halt]].
]

{ #category : #'image segment in/out' }
ObjectMemory >> verifyCleanHeaders [
	| oop |
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory] whileTrue:
		[(self isFreeObject: oop)
			ifTrue: ["There should only be one free block at end of memory."
					(self objectAfter: oop) = endOfMemory
						ifFalse: [self error: 'Invalid obj with HeaderTypeBits = Free.']]
			ifFalse: [(self isMarked: oop) ifTrue:
						[self error: 'Invalid obj with MarkBit set.']].
		oop := self objectAfter: oop]
]

{ #category : #'memory access' }
ObjectMemory >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	"?!*#$%! _Terrible_ name. Call it what it is.
	 VMBIGENDIAN or VMLITTLEENDIAN.  Dont leave us guessing!!!!
	 Alas this has to remain for backward compatibility."

	^VMBIGENDIAN ifTrue: [1] ifFalse: [0]
]

{ #category : #'header formats' }
ObjectMemory >> weakArrayFormat [
	<api>
	<cmacro>
	^4
]

{ #category : #finalization }
ObjectMemory >> weakFinalizerCheck: oop [
	"Our oop has at least 2 non-weak fixed slots (this is assured before entering this method, in
	#finalizeReference:.
	We are assuming that if its first non-weak field is an instance of ClassWeakFinalizationList class,
	then we should add this oop to that list, by storing it to list's first field and
	also, updating the oop's 2nd fixed slot to point to the value which we overridden:
	
	list := oop instVarAt: 1.
	list class == WeakFinalizationList ifTrue: [
		first := list instVarAt: 1.
		oop instVarAt: 2 put: first.
		list instVarAt: 1 put: oop ]	"
	<inline: true>
	| listOop listItemOop |

	listOop := self fetchPointer: 0 ofObject: oop.
	(self fetchClassOf: listOop) = (self splObj: ClassWeakFinalizer) ifTrue:
		[listItemOop := self fetchPointer: 0 ofObject: listOop.
		 self storePointer: 1 ofObject: oop withValue: listItemOop. 
		 self storePointer: 0 ofObject: listOop withValue: oop]
]

{ #category : #'debug printing' }
ObjectMemory >> whereIsMaybeHeapThing: anOop [
	<returnTypeC: 'char *'>
	(self oop: anOop isGreaterThanOrEqualTo: self startOfMemory andLessThan: endOfMemory) ifTrue:
		[(self oop: anOop isLessThan: freeBlock) ifTrue:
			[^' is in old space'].
		 ^' is in new space'].
	^nil
]

{ #category : #'interpreter access' }
ObjectMemory >> wordSize [
	"Answer the manager's word size, which is assumed to be equivalent to the underlying machine's word size."
	^4
]
