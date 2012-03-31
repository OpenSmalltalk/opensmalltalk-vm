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
		'VMObjectIndices',
		'VMSqueakV3BytecodeConstants',
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

{ #category : #accessing }
ObjectMemory class >> bytesPerWord [
	"Answer the width of an object pointer, in bytes."

	^BytesPerWord
]

{ #category : #translation }
ObjectMemory class >> declareCAsOop: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: 'usqInt']
]

{ #category : #translation }
ObjectMemory class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		var: #memory
		declareC: 'static usqInt memory'.
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
			#gcBiasToGrowThreshold }
		in: aCCodeGenerator.
	aCCodeGenerator
		var: #headerTypeBytes type: 'const sqInt' array: HeaderTypeExtraBytes.
	self declareC: #(gcStartUsecs statFullGCUsecs statIncrGCUsecs statIGCDeltaUsecs)
		as: #usqLong
		in: aCCodeGenerator
]

{ #category : #translation }
ObjectMemory class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #initialization }
ObjectMemory class >> initBytesPerWord: nBytes [

	BytesPerWord := nBytes.
	ShiftForWord := (BytesPerWord log: 2) rounded.
	"The following is necessary to avoid confusing the compiler with shifts that are larger than the width of the type on which they operate.  In gcc, such shifts cause incorrect code to be generated."
	BytesPerWord = 8
		ifTrue:					"64-bit VM"
			[Byte0Mask := 16r00000000000000FF.	Byte0Shift := 0.
			 Byte1Mask := 16r000000000000FF00.	Byte1Shift := 8.
			 Byte2Mask := 16r0000000000FF0000.	Byte2Shift := 16.
			 Byte3Mask := 16r00000000FF000000.	Byte3Shift := 24.
			 Byte4Mask := 16r000000FF00000000.	Byte4Shift := 32.
			 Byte5Mask := 16r0000FF0000000000.	Byte5Shift := 40.
			 Byte6Mask := 16r00FF000000000000.	Byte6Shift := 48.
			 Byte7Mask := 16rFF00000000000000.	Byte7Shift := 56.
			 Bytes3to0Mask := 16r00000000FFFFFFFF.
			 Bytes7to4Mask := 16rFFFFFFFF00000000]
		ifFalse:					"32-bit VM"
			[Byte0Mask := 16r00000000000000FF.	Byte0Shift := 0.
			 Byte1Mask := 16r000000000000FF00.	Byte1Shift := 8.
			 Byte2Mask := 16r0000000000FF0000.	Byte2Shift := 16.
			 Byte3Mask := 16r00000000FF000000.	Byte3Shift := 24.
			 Byte4Mask := 16r0000000000000000.	Byte4Shift := 0.		"unused"
			 Byte5Mask := 16r0000000000000000.	Byte5Shift := 0.		"unused"
			 Byte6Mask := 16r0000000000000000.	Byte6Shift := 0.		"unused"
			 Byte7Mask := 16r0000000000000000.	Byte7Shift := 0.		"unused"
			 Bytes3to0Mask := 16r0000000000000000.					"unused"
			 Bytes7to4Mask := 16r0000000000000000					"unused"].
	Byte1ShiftNegated := Byte1Shift negated.
	Byte3ShiftNegated := Byte3Shift negated.
	Byte4ShiftNegated := Byte4Shift negated.
	Byte5ShiftNegated := Byte5Shift negated.
	Byte7ShiftNegated := Byte7Shift negated.
	"N.B.  This is *not* output when generating the interpreter file.
	 It is left to the various sqConfig.h files to define correctly."
	VMBIGENDIAN := Smalltalk endianness == #big
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
	ClassBlockClosureCompactIndex := 0 "12". "Prospective.  Currently TranslatedMethod class"
	ClassByteStringCompactIndex := 11.
	ClassBlockContextCompactIndex := 13.
	ClassMethodContextCompactIndex := 14
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
ObjectMemory class >> initializePrimitiveErrorCodes [
	"Define the VM's primitive error codes.  N.B. these are
	 replicated in platforms/Cross/vm/sqVirtualMachine.h."
	"ObjectMemory initializePrimitiveErrorCodes"
	| pet |
	PrimErrTableIndex := 51. "Zero-relative"
	"See SmalltalkImage>>recreateSpecialObjectsArray for the table definition.
	 If the table exists and is large enough the corresponding entry is returned as
	 the primitive error, otherwise the error is answered numerically."
	pet := Smalltalk specialObjectsArray at: PrimErrTableIndex + 1 ifAbsent: [#()].
	pet isArray ifFalse: [pet := #()].
	PrimNoErr := 0. "for helper methods that need to answer success or an error code."
	PrimErrGenericFailure	:= pet indexOf: nil ifAbsent: 1.
	PrimErrBadReceiver		:= pet indexOf: #'bad receiver' ifAbsent: 2.
	PrimErrBadArgument	:= pet indexOf: #'bad argument' ifAbsent: 3.
	PrimErrBadIndex		:= pet indexOf: #'bad index' ifAbsent: 4.
	PrimErrBadNumArgs	:= pet indexOf: #'bad number of arguments' ifAbsent: 5.
	PrimErrInappropriate	:= pet indexOf: #'inappropriate operation' ifAbsent: 6.
	PrimErrUnsupported	:= pet indexOf: #'unsupported operation' ifAbsent: 7.
	PrimErrNoModification	:= pet indexOf: #'no modification' ifAbsent: 8.
	PrimErrNoMemory		:= pet indexOf: #'insufficient object memory' ifAbsent: 9.
	PrimErrNoCMemory		:= pet indexOf: #'insufficient C memory' ifAbsent: 10.
	PrimErrNotFound		:= pet indexOf: #'not found' ifAbsent: 11.
	PrimErrBadMethod		:= pet indexOf: #'bad method' ifAbsent: 12.
	PrimErrNamedInternal	:= pet indexOf: #'internal error in named primitive machinery' ifAbsent: 13.
	PrimErrObjectMayMove	:= pet indexOf: #'object may move' ifAbsent: 14.
	PrimErrLimitExceeded	:= pet indexOf: #'resource limit exceeded' ifAbsent: 15
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
	"PrimErrTableIndex := 51. in Interpreter class>>initializePrimitiveErrorCodes"
	ClassAlien := 52.
	SelectorInvokeCallback := 53.
	ClassUnsafeAlien := 54.

	ClassWeakFinalizer := 55.

	ForeignCallbackProcess := 56.

	SelectorCounterTripped := 57
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

	self initializeSpecialObjectIndices.
	self initializeCompactClassIndices.
	self initializePrimitiveErrorCodes.
	self initializeObjectHeaderConstants.

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

{ #category : #translation }
ObjectMemory class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^'memory' = var
]

{ #category : #translation }
ObjectMemory class >> requiredMethodNames [
	"return the list of method names that should be retained for export or other support reasons"
	^self exportAPISelectors
]

{ #category : #translation }
ObjectMemory class >> unsignedIntegerSuffix [
	"Answer the suffix that should be appended to unsigned integer literals in generated code."

	^BytesPerWord = 4 ifTrue: ['UL'] ifFalse: ['ULL']
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
	<asmLabel: false>
	offsetBytes = 0 ifTrue: [^nil].
	fieldAddr := oop + (self lastPointerOf: oop).
	[self oop: fieldAddr isGreaterThan: oop]
		whileTrue: [fieldOop := self longAt: fieldAddr.
			(self isIntegerObject: fieldOop)
				ifFalse: [self longAt: fieldAddr put: fieldOop + offsetBytes].
			fieldAddr := fieldAddr - BytesPerWord].
	(self headerType: oop) ~= HeaderTypeShort
		ifTrue: ["adjust class header if not a compact class"
			classHeader := self longAt: oop - BytesPerWord.
			newClassOop := (classHeader bitAnd: AllButTypeMask) + offsetBytes.
			self longAt: oop - BytesPerWord put: (newClassOop bitOr: (classHeader bitAnd: TypeMask))]
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
	[fieldOffset >= BaseHeaderSize] whileTrue:
		[(self oop: (self longAt: array1 + fieldOffset) isLessThan: youngStart)
			ifTrue: [^ false].
		(self oop: (self longAt: array2 + fieldOffset) isLessThan: youngStart)
			ifTrue: [^ false].
		fieldOffset := fieldOffset - BytesPerWord].
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
	newObj := self allocateChunk: byteSize + (hdrSize - 1 * BytesPerWord).
	hdrSize > 1 ifTrue: [remappedClassOop := self popRemappableOop].

	hdrSize = 3
		ifTrue: [self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + BytesPerWord put: (remappedClassOop bitOr: HeaderTypeSizeAndClass).
			self longAt: newObj + (BytesPerWord*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
			newObj := newObj + (BytesPerWord*2)].

	hdrSize = 2
		ifTrue: [self longAt: newObj put: (remappedClassOop bitOr: HeaderTypeClass).
			self longAt: newObj + BytesPerWord put: (baseHeader bitOr: HeaderTypeClass).
			newObj := newObj + BytesPerWord].

	hdrSize = 1
		ifTrue: [self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].
	"clear new object"
	doFill ifTrue:
		[| fillWord end i |
		 fillWord := format <= 4
					ifTrue: [nilObj] "if pointers, fill with nil oop"
					ifFalse: [0].
		 end := newObj + byteSize.
		 i := newObj + BytesPerWord.
		 [i < end] whileTrue:
			[self longAt: i put: fillWord.
			 i := i + BytesPerWord]].
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
	(self oop: (self sizeOfFree: freeBlock) isLessThan: byteSize + BaseHeaderSize)
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

{ #category : #'header access' }
ObjectMemory >> baseHeader: oop [

	^ self longAt: oop
]

{ #category : #'header access' }
ObjectMemory >> baseHeader: oop put: aWord [

	^ self longAt: oop put: aWord
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

	| header fwdBlock |
	"If labelled, gcc duplicates the label when inlining updatePointersInRangeFrom:to:"
	<asmLabel: false> 
	header := self longAt: oop.
	(header bitAnd: MarkBit) ~= 0
		ifTrue: ["This oop is forwarded"
				fwdBlock := (header bitAnd: AllButMarkBitAndTypeMask) << 1.
				self assert: (self fwdBlockValid: fwdBlock).
				self noteAsRoot: oop headerLoc: fwdBlock + BytesPerWord]
		ifFalse: ["Normal -- no forwarding"
				self noteAsRoot: oop headerLoc: oop]
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

{ #category : #'indexing primitive support' }
ObjectMemory >> byteLengthOf: oop [
	"Return the number of indexable bytes in the given object. This is basically a special copy of lengthOf: for BitBlt."
	| header sz fmt |
	header := self baseHeader: oop.
	sz := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [(self sizeHeader: oop) bitAnd: AllButTypeMask]
			ifFalse: [header bitAnd: SizeMask].
	fmt := self formatOfHeader: header.
	^fmt < 8
		ifTrue: [(sz - BaseHeaderSize)]  "words"
		ifFalse: [(sz - BaseHeaderSize) - (fmt bitAnd: 3)]  "bytes"
]

{ #category : #'object format' }
ObjectMemory >> byteSizeOf: oop [
	<api>
	| header format size |
	(self isIntegerObject: oop) ifTrue:[^0].
	header := self baseHeader: oop.
	format := self formatOfHeader: header.
	size := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
				ifTrue: [(self sizeHeader: oop) bitAnd: LongSizeMask]
				ifFalse: [header bitAnd: SizeMask].
	size := size - (header bitAnd: Size4Bit).
	^format < 8
		ifTrue: [ size - BaseHeaderSize "32-bit longs"]
		ifFalse: [ (size - BaseHeaderSize) - (format bitAnd: 3) "bytes"]
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
			fmt >= 8 ifTrue:
				["oop contains bytes; unswap"
				wordAddr := oop + BaseHeaderSize.
				fmt >= 12 ifTrue: "compiled method; start after methodHeader and literals"
					[wordAddr := wordAddr + BytesPerWord + ((self literalCountOf: oop) * BytesPerWord)].
				self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
			fmt = 6  ifTrue: "Bitmap, Float etc"
				[(self compactClassIndexOf: oop) = ClassFloatCompactIndex
					ifTrue:
						[flipFloatWords ifTrue:
							[temp := self longAt: oop + BaseHeaderSize.
							 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
							 self longAt: oop + BaseHeaderSize + 4 put: temp]]
					ifFalse:
						[BytesPerWord = 8 ifTrue:
							["Object contains 32-bit half-words packed into 64-bit machine words."
							wordAddr := oop + BaseHeaderSize.
							self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]]]].
			oop := self objectAfter: oop]
]

{ #category : #'image save/restore' }
ObjectMemory >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."
	<api>
	<returnTypeC: #sqInt>
	self cppIf: BytesPerWord = 4
		ifTrue:
			[^ ((w bitShift: Byte3ShiftNegated) bitAnd: Byte0Mask)
			 + ((w bitShift: Byte1ShiftNegated) bitAnd: Byte1Mask)
			 + ((w bitShift: Byte1Shift         ) bitAnd: Byte2Mask)
			 + ((w bitShift: Byte3Shift         ) bitAnd: Byte3Mask)]
		ifFalse:
			[^ ((w bitShift: Byte7ShiftNegated) bitAnd: Byte0Mask)
			 + ((w bitShift: Byte5ShiftNegated) bitAnd: Byte1Mask)
			 + ((w bitShift: Byte3ShiftNegated) bitAnd: Byte2Mask)
			 + ((w bitShift: Byte1ShiftNegated) bitAnd: Byte3Mask)
			 + ((w bitShift: Byte1Shift         ) bitAnd: Byte4Mask)
			 + ((w bitShift: Byte3Shift         ) bitAnd: Byte5Mask)
			 + ((w bitShift: Byte5Shift         ) bitAnd: Byte6Mask)
			 + ((w bitShift: Byte7Shift         ) bitAnd: Byte7Mask)]
]

{ #category : #allocation }
ObjectMemory >> bytesLeft: includingSwap [
	^(self sizeOfFree: freeBlock) "already commited"
		+ (self sqMemoryExtraBytesLeft: includingSwap).
]

{ #category : #initialization }
ObjectMemory >> bytesPerWord [
	"Answer the size of an object pointer in bytes."

	^BytesPerWord
]

{ #category : #'interpreter access' }
ObjectMemory >> changeClassOf: rcvr to: argClass [
	"Attempt to change the class of the receiver into the class of the the argument given that the
	 format of the receiver matches the format of the argument. If successful answer 0, otherwise
	 answer an error code indicating the reason for failure.  Fail if receiver or argument are
	 SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when
	 the format of the receiver is different from the format of the argument's class, or when the
	 arguments class is fixed and the receiver's size differs from the size that an instance of the
	 argument's class should have."
	| classHdr sizeHiBits byteSize argFormat rcvrFormat rcvrHdr ccIndex |
	"Check what the format of the class says"
	classHdr := self formatOfClass: argClass. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits := (classHdr bitAnd: 16r60000) >> 9.
	classHdr := classHdr bitAnd: 16r1FFFF.
	byteSize := (classHdr bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"

	"Check the receiver's format against that of the class"
	argFormat := self formatOfHeader: classHdr.
	rcvrHdr := self baseHeader: rcvr.
	rcvrFormat := self formatOfHeader: rcvrHdr.
	"If the receiver is a byte object we need to clear the number of odd bytes from the format."
	rcvrFormat > 8 ifTrue:
		[rcvrFormat := rcvrFormat bitAnd: 16rC].
	argFormat = rcvrFormat ifFalse:
		[^PrimErrInappropriate]. "no way"

	"For fixed field classes, the sizes must match.
	Note: byteSize-4 because base header is included in class size."
	argFormat < 2
		ifTrue:
			[(byteSize - BaseHeaderSize) ~= (self byteSizeOf: rcvr) ifTrue:
				[^PrimErrBadReceiver]]
		ifFalse:
			[argFormat = 3 ifTrue: "For indexable plus fixed fields the receiver must be at least big enough."
				[(byteSize - BaseHeaderSize) > (self byteSizeOf: rcvr) ifTrue:
					[^PrimErrBadReceiver]]].

	(self headerTypeOfHeader: rcvrHdr) = HeaderTypeShort
		ifTrue: "Compact classes. Check if the arg's class is compact and exchange ccIndex"
			[ccIndex := classHdr bitAnd: CompactClassMask.
			ccIndex = 0 ifTrue:
				[^PrimErrInappropriate]. "class is not compact"
			self cppIf: IMMUTABILITY
				ifTrue: [(rcvrHdr bitAnd: ImmutabilityBit) ~= 0 ifTrue:
							[^PrimErrNoModification]].
			self longAt: rcvr put:
				(((self longAt: rcvr) bitAnd: CompactClassMask bitInvert32) bitOr: ccIndex)]
		ifFalse: "Exchange the class pointer, which could make rcvr a root for argClass"
			[self cppIf: IMMUTABILITY
				ifTrue: [(rcvrHdr bitAnd: ImmutabilityBit) ~= 0 ifTrue:
							[^PrimErrNoModification]].
			self longAt: rcvr-BaseHeaderSize put: (argClass bitOr: (self headerType: rcvr)).
			(self oop: rcvr isLessThan: youngStart) ifTrue:
				[self possibleRootStoreInto: rcvr value: argClass]].
	"ok"
	^0
]

{ #category : #'plugin support' }
ObjectMemory >> characterTable [
	<api>
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

{ #category : #initialization }
ObjectMemory >> checkCompactIndex: compactIndex isClass: specialIndex named: name [
	"Check that a class the VM assumes is compact has the right index."
	<inline: true> "macrofication of the name arg in invalidCompactClassError only works if this method is inlined so the name is a string literal not a parameter"
	(compactIndex ~= 0
	 and: [(self splObj: specialIndex) ~= (self fetchPointer: compactIndex - 1
											ofObject: (self splObj: CompactClasses))]) ifTrue:
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
				 (hdr bitAnd: RootBit) ~= 0 ifTrue:
					[numRootsInHeap := numRootsInHeap + 1].
				 (self compactClassIndexOfHeader: hdr) = 0 ifTrue:
					[fieldOop := (self classHeader: obj) bitAnd: AllButTypeMask.
					 ((self isIntegerObject: fieldOop)
					   or: [(self heapMapAtWord: (self pointerForOop: fieldOop)) = 0]) ifTrue:
						[self print: 'object leak in '; printHex: obj; print: ' class = '; printHex: fieldOop; cr.
						 ok := false]].
				 fmt := self formatOfHeader: hdr.
				 (fmt <= 4 "pointers" or: [fmt >= 12 "compiled method"]) ifTrue:
					[fmt >= 12
						ifTrue: [fi := (self literalCountOf: obj) + 1 "+ 1 = methodHeader slot"]
						ifFalse: [(fmt = 3 and: [self isContextHeader: hdr])
									ifTrue: [fi := CtxtTempFrameStart + (self fetchStackPointerOf: obj)]
									ifFalse: [fi := self lengthOf: obj]].
					[(fi := fi - 1) >= 0] whileTrue:
						[fieldOop := self fetchPointer: fi ofObject: obj.
						 (self isNonIntegerObject: fieldOop) ifTrue:
							[(fieldOop bitAnd: BytesPerWord - 1) ~= 0
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
		 ok := false].
	1 to: rootTableCount do:
		[:ri|
		obj := rootTable at: ri.
		(obj bitAnd: BytesPerWord - 1) ~= 0
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
						 (hdr bitAnd: RootBit) = 0 ifTrue:
							[self print: 'non-root in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
							 ok := false]]]].
	1 to: remapBufferCount do:
		[:ri|
		obj := remapBuffer at: ri.
		(obj bitAnd: BytesPerWord - 1) ~= 0
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
		(obj bitAnd: BytesPerWord - 1) ~= 0
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
	((oop \\ BytesPerWord) = 0)
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
		((oop >= BytesPerWord) and: [(self headerType: oop - BytesPerWord) = type])
			ifFalse: [ self print: 'class header word has wrong type'; cr. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (BytesPerWord*2)) and:
		 [(self headerType: oop - (BytesPerWord*2)) = type and:
		 [(self headerType: oop - BytesPerWord) = type]])
			ifFalse: [ self print: 'class header word has wrong type'; cr. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self print: 'oop has an unknown format type'; cr. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	BytesPerWord = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self print: 'unused header bit 30 is set; should be zero'; cr. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self print: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: RootBit) = 1 and:
	 [oop >= youngStart])
		ifTrue: [ self print: 'root bit is set in a young object'; cr. ^false ].
	^true

]

{ #category : #'memory access' }
ObjectMemory >> checkOopIntegrity: obj named: name [
	<inline: false>
	<var: #name type: #'char *'>
	(self heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
		[^true].
	self print: name; print: ' leak '; printHex: obj; cr.
	^false
]

{ #category : #'memory access' }
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

	^ self longAt: oop - BaseHeaderSize
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

{ #category : #'memory access' }
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
			self longAt: oop put: ((self longAt: oop) bitAnd: AllButRootBit).
			rootTable at: i put: 0].
	rootTableCount := 0
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
	toIndex := newChunk - BytesPerWord.  "loop below uses pre-increment"
	fromIndex := (remappedOop - extraHdrBytes) - BytesPerWord.
	lastFrom := fromIndex + bytes.
	[fromIndex < lastFrom] whileTrue:
		[self longAt: (toIndex := toIndex + BytesPerWord) put: (self longAt: (fromIndex := fromIndex + BytesPerWord))].
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
	 index in the base header indicate that the class is in the class header word."
	<api>
	| classesArray |
	classesArray := self fetchPointer: CompactClasses ofObject: self specialObjectsOop.
	^self fetchPointer: ccIndex - 1 ofObject: classesArray
]

{ #category : #'header access' }
ObjectMemory >> compactClassIndexOf: oop [
	<inline: true>
	^((self baseHeader: oop) >> 12) bitAnd: 16r1F
]

{ #category : #'header access' }
ObjectMemory >> compactClassIndexOfHeader: header [
	<api>
	<inline: true>
	^(header >> 12) bitAnd: 16r1F
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
	[fieldOffset >= BaseHeaderSize] whileTrue:
		[(self internalIsImmutable: (self longAt: array1 + fieldOffset)) ifTrue: [^ false].
		 (self internalIsImmutable: (self longAt: array2 + fieldOffset)) ifTrue: [^ false].
		 fieldOffset := fieldOffset - BytesPerWord].
	^ true
]

{ #category : #become }
ObjectMemory >> containOnlyOops: array [
	"Return true if the array contains a small integer. You 
	  can't become: SmallIntegers!"
	| fieldOffset |
	fieldOffset := self lastPointerOf: array.
	"same size as array2"
	[fieldOffset >= BaseHeaderSize] whileTrue:
		[(self isIntegerObject: (self longAt: array + fieldOffset)) ifTrue: [^ false].
		 fieldOffset := fieldOffset - BytesPerWord].
	^true
]

{ #category : #become }
ObjectMemory >> containOnlyOops: array1 and: array2 [ 
	"Return true if neither array contains a small integer. You 
	can't become: integers!"
	| fieldOffset |
	fieldOffset := self lastPointerOf: array1.
	"same size as array2"
	[fieldOffset >= BaseHeaderSize]
		whileTrue: [(self isIntegerObject: (self longAt: array1 + fieldOffset)) ifTrue: [^ false].
			(self isIntegerObject: (self longAt: array2 + fieldOffset)) ifTrue: [^ false].
			fieldOffset := fieldOffset - BytesPerWord].
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
	self transfer: extraSize + bodySize // BytesPerWord  "wordCount"
		from: oop - extraSize
		to: lastSeg+BytesPerWord.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr := lastSeg+BytesPerWord + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: AllButRootBit - MarkBit).

	self forward: oop to: (lastSeg+BytesPerWord + extraSize - segmentWordArray)
		savingOopAt: oopPtr
		andHeaderAt: hdrPtr.

	"Return new end of segment"
	^lastSeg + extraSize + bodySize
]

{ #category : #'plugin support' }
ObjectMemory >> displayObject [
	^self splObj: TheDisplay
]

{ #category : #accessing }
ObjectMemory >> endOfMemory [
	^endOfMemory
]

{ #category : #accessing }
ObjectMemory >> endOfMemory: aValue [
	^endOfMemory := aValue
]

{ #category : #'header access' }
ObjectMemory >> ensureBehaviorHash: oop [

	^self hashBitsOf: oop
]

{ #category : #'forward compatibility' }
ObjectMemory >> enterIntoClassTable: aBehavior [
	"The old ObjectMemory should never be called upon to enter anything into the class table.
	 Alas 0 is a valid identityhash in the Squeak V3 objrep so primitiveBehaviorHash may
	 ask to enter into the table a class with a 0 id hash.  SImply ignore the request."
	^0
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

{ #category : #'interpreter access' }
ObjectMemory >> fetchByte: byteIndex ofObject: oop [

	^ self byteAt: oop + BaseHeaderSize + byteIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchClassOf: oop [ 
	| ccIndex |
	<inline: true>
	<asmLabel: false>
	(self isIntegerObject: oop) ifTrue: [^self splObj: ClassInteger].

	(ccIndex := (self compactClassIndexOf: oop)) = 0
		ifTrue: [^(self classHeader: oop) bitAnd: AllButTypeMask]
		ifFalse: "look up compact class"
			[^self fetchPointer: ccIndex - 1
				ofObject: (self splObj: CompactClasses)]
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchClassOfNonInt: oop [ 
	| ccIndex |
	<inline: true>
	<asmLabel: false>
	(ccIndex := (self compactClassIndexOf: oop)) = 0
		ifTrue: [^(self classHeader: oop) bitAnd: AllButTypeMask]
		ifFalse: "look up compact class"
			[^self fetchPointer: ccIndex - 1
				ofObject: (self splObj: CompactClasses)]
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchLong32: fieldIndex ofObject: oop [
	" index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^ self long32At: oop + BaseHeaderSize + (fieldIndex << 2)
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchLong32LengthOf: objectPointer [
	"Gives size appropriate for, eg, fetchLong32"

	| sz |
	sz := self sizeBitsOf: objectPointer.
	^ (sz - BaseHeaderSize) >> 2
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchPointer: fieldIndex ofObject: oop [
	"index by word size, and return a pointer as long as the word size"

	^ self longAt: oop + BaseHeaderSize + (fieldIndex << ShiftForWord)
]

{ #category : #'interpreter access' }
ObjectMemory >> fetchWordLengthOf: objectPointer [
	"NOTE: this gives size appropriate for fetchPointer: n, but not in general for, eg, fetchLong32, etc."

	| sz |
	sz := self sizeBitsOf: objectPointer.
	^ (sz - BaseHeaderSize) >> ShiftForWord
]

{ #category : #finalization }
ObjectMemory >> finalizeReference: oop [ 
	"During sweep phase we have encountered a weak reference. 
	Check if  its object has gone away (or is about to) and if so, signal a 
	semaphore. "
	"Do *not* inline this in sweepPhase - it is quite an unlikely 
	case to run into a weak reference"
	| weakOop oopGone chunk firstField lastField |
	<inline: false>
	<var: #oop type: 'usqInt'>
	<var: #weakOop type: 'usqInt'>
	firstField := BaseHeaderSize + ((self nonWeakFieldsOf: oop) << ShiftForWord).
	lastField := self lastPointerOf: oop.
	firstField to: lastField by: BytesPerWord do: [:i | 
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
						ifFalse: [oopGone := (self isMarked: weakOop) not].
					oopGone ifTrue: ["Store nil in the pointer and signal the  interpreter"
							self longAt: oop + i put: nilObj.
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

{ #category : #'object format' }
ObjectMemory >> firstFixedField: oop [

	<returnTypeC: #'void *'>
	^ self pointerForOop: oop + BaseHeaderSize
]

{ #category : #'object format' }
ObjectMemory >> firstIndexableField: oop [
	"NOTE: overridden in various simulator subclasses to add coercion to CArray, so please duplicate any changes"
	| hdr fmt totalLength fixedFields |
	<returnTypeC: #'void *'>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	fmt <= 4 ifTrue: "<= 4 pointer"
		["pointer; may need to delve into the class format word"
		totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
		fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
		^self pointerForOop: oop + BaseHeaderSize + (fixedFields << ShiftForWord)].
	^self pointerForOop: oop + BaseHeaderSize
]

{ #category : #'object enumeration' }
ObjectMemory >> firstObject [
	"Return the first object or free chunk in the heap."

	^ self oopFromChunk: self startOfMemory
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
	<asmLabel: false>
	((fmt > 4) or: [fmt = 2]) ifTrue: [^0].  "indexable fields only"
	fmt < 2 ifTrue: [^wordLength].  "fixed fields only (zero or more)"
	
	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOfNonInt: oop.
	classFormat := self formatOfClass: class.
	^(classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1
]

{ #category : #accessing }
ObjectMemory >> forceTenureFlag [
	^forceTenureFlag
]

{ #category : #accessing }
ObjectMemory >> forceTenureFlag: aValue [
	^forceTenureFlag := aValue
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
	<inline: true>
	^((self baseHeader: oop) >> 8) bitAnd: 16rF
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

{ #category : #'header access' }
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
	^header >> 8 bitAnd: 16rF
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
	self postGCAction.
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
	self setSizeOfFree: freeBlock to: BaseHeaderSize.
	self setEndOfMemory: freeBlock + BaseHeaderSize.

	"make a fake free chunk at endOfMemory for use as a sentinal in memory scans"
	self setSizeOfFree: endOfMemory to: BaseHeaderSize.

	"use all memory free between freeBlock and memoryLimit for forwarding table"
	"Note: Forward blocks must be quadword aligned."
	fwdTableNext := (endOfMemory + BaseHeaderSize + 7) bitAnd: WordMask-7.
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

	eom := freeBlock + BaseHeaderSize.
	"use all memory free between freeBlock and memoryLimit for forwarding table"

	"Note: Forward blocks must be quadword aligned."
	fwdFirst := (eom + BaseHeaderSize + 7) bitAnd: WordMask-7.
	self flag: #Dan.  "Above line does not do what it says (quadword is 16 or 32 bytes)"

	fwdLast := memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdLast - fwdFirst) // blkSize  "round down"
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

{ #category : #'header access' }
ObjectMemory >> hashBitsOf: oop [

	^ ((self baseHeader: oop) >> HashBitsOffset) bitAnd: HashMaskUnshifted
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
		 header := self longAt: fwdBlock + BytesPerWord].
	^header
]

{ #category : #'image segment in/out' }
ObjectMemory >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC)"

	wholeWord := self longAt: (self splObj: SelectorDoesNotUnderstand) + BaseHeaderSize.
		"first data word, 'does' "
	^ self imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #'gc -- compaction' }
ObjectMemory >> incCompBody [
	"Move objects to consolidate free space into one big chunk. Return the newly created free chunk."

	| bytesFreed |
	<inline: false>
	"reserve memory for forwarding table"
	self fwdTableInit: BytesPerWord*2.  "Two-word blocks"

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
					fwdBlock := self fwdBlockGet: BytesPerWord*2.
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
			header := self longAt: fwdBlock + BytesPerWord.
			self longAt: oop put: header. "restore the original header"
			bytesToMove := oop - newOop. "move the oop (including any extra header words) "
			sz := self sizeBitsOf: oop.
			firstWord := oop - (self extraHeaderBytes: oop).
			lastWord := oop + sz - BaseHeaderSize.
			target := firstWord - bytesToMove.
			firstWord to: lastWord by: BytesPerWord do:
				[:w | 
				self longAt: target put: (self longAt: w).
				target := target + BytesPerWord]].
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
	rootTableCount >= RootTableSize
		ifTrue: ["root table overflow; cannot do an incremental GC (this should be very rare)"
			statRootTableOverflows := statRootTableOverflows + 1.
			^ self fullGC].

	DoAssertionChecks ifTrue:
		[self reverseDisplayFrom: 8 to: 15.
		 self checkHeapIntegrity.
		 self checkInterpreterIntegrity.
		 self validate].

	self preGCAction: GCModeIncr.
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
	self postGCAction.
	DoAssertionChecks ifTrue:
		[self validate.
		 self checkHeapIntegrity.
		 self checkInterpreterIntegrity.
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
	<asmLabel: false>
	originalHeader := self longAt: oop.
	self assert: fwdBlock ~= nil. "ran out of forwarding blocks in become"
	self assert: (originalHeader bitAnd: MarkBit) = 0. "'object already has a forwarding table entry"
	originalHeaderType := originalHeader bitAnd: TypeMask.
	self longAt: fwdBlock put: newOop.
	self longAt: fwdBlock + BytesPerWord put: originalHeader.
	backFlag ifTrue: [self longAt: fwdBlock + (BytesPerWord*2) put: oop].
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
	^ nilObj
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
	fwdBlockBytes := totalObjectCount bitAnd: WordMask - BytesPerWord + 1.
	(self oop: memoryLimit - fwdBlockBytes isGreaterThanOrEqualTo: firstFree + BaseHeaderSize)
		ifFalse: ["reserve enough space for a minimal free block of BaseHeaderSize bytes"
			fwdBlockBytes := memoryLimit - (firstFree + BaseHeaderSize)].

	"set endOfMemory and initialize freeBlock"
	self setEndOfMemory: memoryLimit - fwdBlockBytes.
	freeBlock := firstFree.
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
	"This is the same as the field stored in every object header"

	^self formatOfHeader: (self formatOfClass: classPointer)
]

{ #category : #'object enumeration' }
ObjectMemory >> instanceAfter: objectPointer [ 
	"Support for instance enumeration. Return the next instance 
	of the class of the given object, or nilObj if the enumeration 
	is complete."
	| classPointer thisObj thisClass |
	classPointer := self fetchClassOfNonInt: objectPointer.
	thisObj := self accessibleObjectAfter: objectPointer.
	[thisObj = nil] whileFalse:
		[thisClass := self fetchClassOfNonInt: thisObj.
		 thisClass = classPointer ifTrue: [^ thisObj].
		 thisObj := self accessibleObjectAfter: thisObj].
	^ nilObj
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
	^byteSize - BaseHeaderSize / BytesPerWord
]

{ #category : #'interpreter access' }
ObjectMemory >> instantiateClass: classPointer indexableSize: size [ 
	"NOTE: This method supports the backward-compatible split instSize field of the 
	class format word. The sizeHiBits will go away and other shifts change by 2 
	when the split fields get merged in an (incompatible) image change."
	<api>
	| hash header1 header2 cClass byteSize format binc header3 hdrSize newObj sizeHiBits bm1 classFormat |
	<inline: false>
	self assert: size >= 0. "'cannot have a negative indexable field count"
	hash := self newObjectHash.
	classFormat := self formatOfClass: classPointer.
	"Low 2 bits are 0"
	header1 := (classFormat bitAnd: 16r1FF00) bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset.
	header2 := classPointer.
	header3 := 0.
	sizeHiBits := (classFormat bitAnd: 16r60000) >> 9.
	cClass := header1 bitAnd: CompactClassMask. "compact class field from format word"
	byteSize := (classFormat bitAnd: SizeMask + Size4Bit) + sizeHiBits.
		"size in bytes -- low 2 bits are 0"
	"Note this byteSize comes from the format word of the class which is pre-shifted
		to 4 bytes per field.  Need another shift for 8 bytes per word..."
	byteSize := byteSize << (ShiftForWord-2).
	format := self formatOfHeader: classFormat.
	self flag: #sizeLowBits.
	format < 8
		ifTrue:
			[format = 6
				ifTrue: ["long32 bitmaps"
					bm1 := BytesPerWord-1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: LongSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: [byteSize := byteSize + (size * BytesPerWord) "Arrays and 64-bit bitmaps"]]
		ifFalse:
			["Strings and Methods"
			bm1 := BytesPerWord-1.
			byteSize := byteSize + size + bm1 bitAnd: LongSizeMask. "round up"
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
	
	hdrSize := header3 > 0
				ifTrue: [3 "requires full header"]
				ifFalse: [cClass = 0 ifTrue: [2] ifFalse: [1]].
	newObj := self allocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3 doFill: true format: format.
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
	(sizeInBytes bitAnd: (BytesPerWord-1)) = 0 ifFalse:
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

{ #category : #simulation }
ObjectMemory >> interpreter [
	<doNotGenerate>
	^self
]

{ #category : #'header access' }
ObjectMemory >> is: oop instanceOf: classOop compactClassIndex: compactClassIndex [
	"Answer if oop is an instance of the given class. If the class has a (non-zero)
	 compactClassIndex use that to speed up the check.  N.B. Inlining should
	 result in classOop not being accessed if compactClassIndex is non-zero."

	| ccIndex |
	<inline: true>
	(self isIntegerObject: oop) ifTrue:
		[^false].

	ccIndex := self compactClassIndexOf: oop.
	compactClassIndex ~= 0 ifTrue:
		[^compactClassIndex == ccIndex].

	^ccIndex = 0
	  and: [((self classHeader: oop) bitAnd: AllButTypeMask) = classOop]
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

{ #category : #'header access' }
ObjectMemory >> isClassOfNonImm: oop equalTo: classOop [
	"Answer if the given (non-immediate) object is an instance of the given class."

	| ccIndex cl |
	<inline: true>
	<asmLabel: false>
	(self isIntegerObject: oop) ifTrue:
		[^false].

	cl := (ccIndex := self compactClassIndexOf: oop) = 0
			ifTrue: [(self classHeader: oop) bitAnd: AllButTypeMask]
			ifFalse: "look up compact class"
				[self fetchPointer: ccIndex - 1
					ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop)].

	^cl = classOop
]

{ #category : #'header access' }
ObjectMemory >> isClassOfNonImm: oop equalTo: classOop compactClassIndex: compactClassIndex [
	"Answer if the given (non-immediate) object is an instance of the given class
	 that may have a compactClassIndex (if compactClassIndex is non-zero).
	 N.B. Inlining and/or compiler optimization should result in classOop not being
	 accessed if compactClassIndex is non-zero."

	| ccIndex |
	<inline: true>
	<asmLabel: false>
	self assert: (self isIntegerObject: oop) not.

	ccIndex := self compactClassIndexOf: oop.
	^compactClassIndex = 0
		ifTrue:
			[ccIndex = 0
				ifTrue: [((self classHeader: oop) bitAnd: AllButTypeMask) = classOop]
				ifFalse: [false]]
		ifFalse:
			[compactClassIndex == ccIndex]
]

{ #category : #'interpreter access' }
ObjectMemory >> isCompiledMethod: oop [
    "Answer whether the argument object is of compiled method format"
	<api>
    ^(self formatOf: oop) >= 12
]

{ #category : #'interpreter access' }
ObjectMemory >> isCompiledMethodHeader: objHeader [
    "Answer whether the argument header has compiled method format"
    ^(self formatOfHeader: objHeader) >= 12
]

{ #category : #contexts }
ObjectMemory >> isContextHeader: aHeader [
	<inline: true>
	"c.f. {BlockContext. MethodContext. PseudoContext} collect: [:class| class -> class indexIfCompact]"
	^ ((aHeader >> 12) bitAnd: 16r1F) = 13			"BlockContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 14]	"MethodContext"
]

{ #category : #contexts }
ObjectMemory >> isContextNonInt: oop [
	<inline: true>
	^self isContextHeader: (self baseHeader: oop)
]

{ #category : #'header access' }
ObjectMemory >> isFreeObject: oop [

	^ (self headerType: oop) = HeaderTypeFree
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
		header := self longAt: fwdBlock + BytesPerWord].
	^(header bitAnd: ImmutabilityBit) ~= 0
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
	"Use a shift and XOR to set the sign bit if and only if the top two bits of the given value are the same, then test the sign bit. Note that the top two bits are equal for exactly those integers in the range that can be represented in 31-bits or 63-bits."

	^ (intValue bitXor: (intValue << 1)) >= 0
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
	^(self compactClassIndexOfHeader: aHeader) == ClassMethodContextCompactIndex
]

{ #category : #'interpreter access' }
ObjectMemory >> isNonIntegerObject: objectPointer [

	^ (objectPointer bitAnd: 1) = 0
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

{ #category : #'interpreter access' }
ObjectMemory >> isYoung: oop [
	<api>
	^(self isNonIntegerObject: oop)
	   and: [self oop: oop isGreaterThanOrEqualTo: youngStart]
]

{ #category : #'garbage collection' }
ObjectMemory >> isYoungRoot: oop [
	"Answer if oop is a root for objects in youngSpace"
	^((self baseHeader: oop) bitAnd: RootBit) ~= 0
]

{ #category : #accessing }
ObjectMemory >> lastHash [
	^lastHash
]

{ #category : #accessing }
ObjectMemory >> lastHash: aValue [
	^lastHash := aValue
]

{ #category : #'object enumeration' }
ObjectMemory >> lastPointerOf: oop [ 
	"Return the byte offset of the last pointer field of the given object.  
	Works with CompiledMethods, as well as ordinary objects. 
	Can be used even when the type bits are not correct."
	| fmt sz methodHeader header contextSize |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue: [(fmt = 3 and: [self isContextHeader: header])
					ifTrue: ["contexts end at the stack pointer"
						contextSize := self fetchStackPointerOf: oop.
						^ CtxtTempFrameStart + contextSize * BytesPerWord].
				sz := self sizeBitsOfSafe: oop.
				^ sz - BaseHeaderSize  "all pointers"].
	fmt < 12 ifTrue: [^ 0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	methodHeader := self longAt: oop + BaseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * BytesPerWord + BaseHeaderSize
]

{ #category : #'gc -- mark and sweep' }
ObjectMemory >> lastPointerOf: oop recordWeakRoot: recordWeakRoot [ "<Boolean>"
	"Return the byte offset of the last pointer field of the given object.  
	 Works with CompiledMethods, as well as ordinary objects. 
	 Can be used even when the type bits are not correct.
	 This is a version of lastPointerOf: for markAndTrace:."
	| fmt sz header contextSize |
	<inline: true>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[fmt >= 3 ifTrue:
			[fmt = 4 ifTrue:
				[(recordWeakRoot and: [weakRootCount >= 0]) ifTrue:
					["And remember as weak root"
					 (weakRootCount := weakRootCount + 1) <= WeakRootTableSize ifFalse:
						[self error: 'weakRoots table overflow'].
					 weakRoots at: weakRootCount put: oop].
				"Do not trace the object's indexed fields if it's a weak class"
				^(self nonWeakFieldsOf: oop) << ShiftForWord].
			"So fmt is 3"
			(self isContextHeader: header) ifTrue:
				["contexts end at the stack pointer avoiding having to init fields beyond it"
				 contextSize := self fetchStackPointerOf: oop.
				 ^CtxtTempFrameStart + contextSize * BytesPerWord]].
		 sz := self sizeBitsOfSafe: oop.
		 ^sz - BaseHeaderSize  "all pointers" ].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	^(self literalCountOf: oop) * BytesPerWord + BaseHeaderSize
]

{ #category : #'gc -- compaction' }
ObjectMemory >> lastPointerWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	the offset of the last pointer in the object in spite of this obstacle. "
	| header fmt size methodHeader contextSize |
	<inline: true>
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := self nacFetchStackPointerOf: oop.
			self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
			^ CtxtTempFrameStart + contextSize * BytesPerWord].
		"do sizeBitsOf: using the header we obtained"
		(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [size := (self sizeHeader: oop) bitAnd: AllButTypeMask]
			ifFalse: [size := header bitAnd: SizeMask].
		^ size - BaseHeaderSize].
	fmt < 12 ifTrue: [^ 0]. "no pointers"
	methodHeader := self longAt: oop + BaseHeaderSize.
	^(self literalCountOfHeader: methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'indexing primitive support' }
ObjectMemory >> lengthOf: oop [
	"Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result."

	<api>
	| header |
	<inline: true>
	<asmLabel: false> 
	header := self baseHeader: oop.
	^self lengthOf: oop baseHeader: header format: (self formatOfHeader: header)
]

{ #category : #'indexing primitive support' }
ObjectMemory >> lengthOf: oop baseHeader: hdr format: fmt [
	"Return the number of indexable bytes or words in the given object. Assume the given oop is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result of this method."

	| sz |
	<inline: true>
	<asmLabel: false> 
	(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ sz := (hdr bitAnd: SizeMask)].
	sz := sz - (hdr bitAnd: Size4Bit).
	fmt <= 4
		ifTrue: [ ^ (sz - BaseHeaderSize) >> ShiftForWord "words"].
	fmt < 8
		ifTrue: [ ^ (sz - BaseHeaderSize) >> 2 "32-bit longs"]
		ifFalse: [ ^ (sz - BaseHeaderSize) - (fmt bitAnd: 3) "bytes"]
]

{ #category : #'image segment in/out' }
ObjectMemory >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

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
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BaseHeaderSize.

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + BaseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
		"Not readable -- try again with reversed bytes..."
		[self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
		data := self longAt: segmentWordArray + BaseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
			"Still NG -- put things back and fail"
			[self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^0]].
	"Reverse the Byte type objects if the data is from opposite endian machine.
	 Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal."
	(data >> 16) = (self imageSegmentVersion >> 16)
		ifFalse: "Reverse the byte-type objects once"
			[segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
				 "Oop of first embedded object"
			self byteSwapByteObjectsFrom: segOop
				to: endSeg + BytesPerWord
				flipFloatsIf: false].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue:
			[DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^0 "out of bounds"].

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
					fieldPtr := fieldPtr + BytesPerWord]
				ifFalse:
					[(fieldOop bitAnd: 3) = 0 ifFalse:
						[^0 "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop := fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr := outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue:
									[^0 "out of bounds"].
								mapOop := self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + 8.
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + BytesPerWord].
					segOop < youngStart ifTrue:
						[self possibleRootStoreInto: segOop value: mapOop]]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse:
			[^0 "inconsistency"].
		fieldPtr := segOop + BaseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse:
				[^0 "inconsistency"].
			fieldPtr := fieldPtr + BytesPerWord].
		segOop := self objectAfter: segOop].

	"Truncate the segment word array to size = BytesPerWord (vers stamp only)"
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: BaseHeaderSize + BytesPerWord + hdrTypeBits]
		ifFalse: [header := self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: SizeMask) + BaseHeaderSize + BytesPerWord].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord
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
	"Use the forwarding table to update the pointers of all non-free objects in the given range of memory. Also remap pointers in root objects which may contains pointers into the given memory range, and don't forget to flush the method cache based on the range"
	| oop |
	<inline: false>
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
			(self isIntegerObject: oop) ifFalse:[self markAndTrace: oop]].

]

{ #category : #'forward compatibility' }
ObjectMemory >> maxIdentityHash [
	^HashMaskUnshifted
]

{ #category : #'interpreter access' }
ObjectMemory >> maybeSplObj: index [
	<api>
	"Return one of the objects in the SpecialObjectsArray, if in range, otherwise ansser nil"
	^index < (self lengthOf: specialObjectsOop) ifTrue:
		[self fetchPointer: index ofObject: specialObjectsOop]
]

{ #category : #accessing }
ObjectMemory >> memory [
	<cmacro: '() memory'>
	^memory
]

{ #category : #accessing }
ObjectMemory >> memory: aValue [
	^memory := aValue
]

{ #category : #accessing }
ObjectMemory >> memoryLimit [
	^memoryLimit
]

{ #category : #allocation }
ObjectMemory >> minSlotsForShortening [
	"HeaderTypeFree free chunks require 1 word of header"
	^1
]

{ #category : #'header access' }
ObjectMemory >> newObjectHash [
	"Answer a new 16-bit pseudo-random number for use as an identity hash."

	lastHash := 13849 + (27181 * lastHash) bitAnd: 65535.
	^ lastHash

]

{ #category : #'interpreter access' }
ObjectMemory >> nilObject [
	<api>
	"For access from BitBlt module & Cogit"
	^ nilObj
]

{ #category : #'object format' }
ObjectMemory >> nonWeakFieldsOf: oop [
	"Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length."
	| class classFormat |
	<inline: false> "No need to inline - we won't call this often"

	self assert: (self isWeakNonInt: oop).

	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOfNonInt: oop.
	classFormat := self formatOfClass: class.
	^(classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1
]

{ #category : #'garbage collection' }
ObjectMemory >> noteAsRoot: oop headerLoc: headerLoc [ 
	"Record that the given oop in the old object area points to an 
	object in the young area. 
	HeaderLoc is usually = oop, but may be an addr in a 
	forwarding block."
	| header |
	<inline: true>
	<asmLabel: false> 
	header := self longAt: headerLoc.
	(header bitAnd: RootBit) = 0
		ifTrue: ["record oop as root only if not already recorded"
			rootTableCount < RootTableRedZone
				ifTrue: ["record root if there is enough room in the roots 
					table "
					rootTableCount := rootTableCount + 1.
					rootTable at: rootTableCount put: oop.
					self longAt: headerLoc put: (header bitOr: RootBit)]
				ifFalse: ["we're getting in the red zone"
					rootTableCount < RootTableSize
						ifTrue: ["but there's still space to record it"
							rootTableCount := rootTableCount + 1.
							rootTable at: rootTableCount put: oop.
							self longAt: headerLoc put: (header bitOr: RootBit).
							"but force an IGC on the next allocation"
							allocationCount := allocationsBetweenGCs + 1]]]
]

{ #category : #'object enumeration' }
ObjectMemory >> objectAfter: oop [ 
	"Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete."
	| sz |
	<api>
	<inline: true>
	<asmLabel: false>
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
	<asmLabel: false>
	header := self longAt: oop.
	(header bitAnd: MarkBit) = 0 ifTrue: [ ^ self objectAfter: oop ].  "oop not forwarded"

	"Assume: mark bit cannot be set on a free chunk, so if we get here,
	 oop is not free and it has a forwarding table entry"

	fwdBlock := (header bitAnd: AllButMarkBitAndTypeMask) << 1.
	self assert: (self fwdBlockValid: fwdBlock).
	realHeader := self longAt: fwdBlock + BytesPerWord.
	"following code is like sizeBitsOf:"
	(realHeader bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ sz := realHeader bitAnd: SizeMask ].

	^ self oopFromChunk: (oop + sz)
]

{ #category : #'object enumeration' }
ObjectMemory >> objectBefore: address [ 
	"Return the object or start of free space immediately preceeding the given
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
	"Return the object or start of free space immediately preceeding the given
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
		[fieldOffset >= BaseHeaderSize] whileTrue:
			[fieldOop := self longAt: oop + fieldOffset.
			(self isObjectForwarded: fieldOop) ifTrue: [^true].
			 fieldOffset := fieldOffset - BytesPerWord]].
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
	(oop >= self startOfMemory and: [oop < endOfMemory])
		ifFalse: [ self error: 'oop is not a valid address'. ^false ].
	((oop \\ BytesPerWord) = 0)
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
		((oop >= BytesPerWord) and: [(self headerType: oop - BytesPerWord) = type])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (BytesPerWord*2)) and:
		 [(self headerType: oop - (BytesPerWord*2)) = type and:
		 [(self headerType: oop - BytesPerWord) = type]])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type'. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	BytesPerWord = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero'. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: RootBit) = 1 and:
	 [oop >= youngStart])
		ifTrue: [ self error: 'root bit is set in a young object'. ^false ].
	^true

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

	oop < freeBlock ifFalse: [^ false].
	((oop \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oop + (self sizeBitsOf: oop)) < freeBlock ifFalse: [^ false].
	oopClass := self cCoerce: (self fetchClassOfNonInt: oop) to: #usqInt.

	(self isIntegerObject: oopClass) ifTrue: [^ false].
	(oopClass < freeBlock) ifFalse: [^ false].
	((oopClass \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) < freeBlock ifFalse: [^ false].
	((self isPointersNonInt: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].
	(self isBytesNonInt: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
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
	entriesNeeded := (self lastPointerOf: array1) // BytesPerWord. "need enough entries for all oops"
	"Note: Forward blocks must be quadword aligned - see fwdTableInit:."
	twoWayFlag
		ifTrue: ["Double the number of blocks for two-way become"
			entriesNeeded := entriesNeeded * 2.
			fwdBlkSize := BytesPerWord * 2]
		ifFalse: ["One-way become needs backPointers in fwd blocks."
			fwdBlkSize := BytesPerWord * 4].
	entriesAvailable := self fwdTableInit: fwdBlkSize.
	entriesAvailable < entriesNeeded
		ifTrue: [self initializeMemoryFirstFree: freeBlock.
			"re-initialize the free block"
			^ false].
	fieldOffset := self lastPointerOf: array1.
	[fieldOffset >= BaseHeaderSize]
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
			fieldOffset := fieldOffset - BytesPerWord].
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
	i := outPointerArray + BaseHeaderSize.
	[i <= lastAddr] whileTrue:
		[self longAt: i put: nilObj.
		i := i + BytesPerWord].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^PrimErrGenericFailure
]

{ #category : #'debug printing' }
ObjectMemory >> printInstancesOf: aClassOop [
	"Scan the heap printing the oops of any and all objects that are instances of aClassOop"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[(self fetchClassOfNonInt: oop) = aClassOop ifTrue:
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
			[i := (self literalCountOf: oop) - 1.
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
		[((self isPointers: oop) or: [self isCompiledMethod: oop]) ifTrue:
			[(self isCompiledMethod: oop)
				ifTrue:
					[i := (self literalCountOf: oop) - 1]
				ifFalse:
					[(self isContext: oop)
						ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
						ifFalse: [i := (self lengthOf: oop) - 1]].
			[i >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[self printHex: oop; print: ' @ '; printNum: i; cr.
					 i := 0].
				 i := i - 1]].
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

	classHeader := self longAt: oop - BytesPerWord.
	classOop := classHeader bitAnd: AllButTypeMask.
	(self isObjectForwarded: classOop) ifTrue:
		[newClassOop := self remappedObj: classOop.
		newClassHeader := newClassOop bitOr: (classHeader bitAnd: TypeMask).
		self longAt: oop - BytesPerWord put: newClassHeader.
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
	[fieldOffset >= BaseHeaderSize] whileTrue:
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
		fieldOffset := fieldOffset - BytesPerWord].
	self remapClassOf: oop
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
	| root |
	<export: true>
	<var: #varLoc type: #'sqInt *'>
	<var: #root type: #'sqInt *'>
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
	fwdBlock := (fwdHeader bitAnd: AllButMarkBitAndTypeMask) << 1.
	self assert: (fwdHeader bitAnd: MarkBit) ~= 0.
	self assert: (self fwdBlockValid: fwdBlock).
	self longAt: oop put: (self longAt: fwdBlock + BytesPerWord)
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
	[fieldOffset >= BaseHeaderSize]
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
			fieldOffset := fieldOffset - BytesPerWord]
]

{ #category : #become }
ObjectMemory >> restoreHeadersAfterForwardBecome: copyHashFlag [ 
	"Forward become leaves us with no original oops in the 
	mutated object list, 
	so we must enumerate the (four-word) forwarding blocks 
	where we have stored backpointers."
	"This loop start is copied from fwdTableInit:"
	| oop1 fwdBlock oop2 hdr1 hdr2 |
	fwdBlock := endOfMemory + BaseHeaderSize + 7 bitAnd: WordMask - 7.
	self flag: #Dan.  "See flag comment in fwdTableInit: (dtl)"
	fwdBlock := fwdBlock + (BytesPerWord*4).
	"fwdBlockGet: did a pre-increment"
	[self oop: fwdBlock isLessThanOrEqualTo: fwdTableNext
	"fwdTableNext points to the last active block"]
		whileTrue: [oop1 := self longAt: fwdBlock + (BytesPerWord*2).
			"Backpointer to mutated object."
			oop2 := self longAt: fwdBlock.
			self restoreHeaderOf: oop1.
			copyHashFlag
				ifTrue: ["Change the hash of the new oop (oop2) to be that of the old (oop1) 
					so mutated objects in hash structures will be 
					happy after the change."
					hdr1 := self longAt: oop1.
					hdr2 := self longAt: oop2.
					self longAt: oop2 put: ((hdr2 bitAnd: AllButHashBits) bitOr: (hdr1 bitAnd: HashBits))].
			fwdBlock := fwdBlock + (BytesPerWord*4)]
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
		tablePtr := tablePtr + BytesPerWord].
	tablePtr := firstOut.
	[self oop: tablePtr isLessThanOrEqualTo: lastOut] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr := tablePtr + BytesPerWord].
	
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
	self flag: #Dan.
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr := addr + BytesPerWord].
]

{ #category : #'image save/restore' }
ObjectMemory >> reverseWordsFrom: startAddr to: stopAddr [
	"Word-swap the given range of memory, excluding stopAddr."

	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self wordSwapped: (self longAt: addr)).
		addr := addr + BytesPerWord].
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

{ #category : #accessing }
ObjectMemory >> rootTable: aValue [
	^rootTable := aValue
]

{ #category : #accessing }
ObjectMemory >> rootTableCount [
	^rootTableCount
]

{ #category : #accessing }
ObjectMemory >> rootTableCount: aValue [
	^rootTableCount := aValue
]

{ #category : #'debug printing' }
ObjectMemory >> safePrintStringOf: oop [
	"Version of printStringOf: that copes with forwarding during garbage collection."
	| fmt header cnt i |
	<inline: false>
	(self isIntegerObject: oop) ifTrue:
		[^nil].
	(oop between: self startOfMemory and: freeBlock) ifFalse:
		[^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[^nil].
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt < 8 ifTrue: [ ^nil ].

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
	self assert: (newEndOfMemory bitAnd: BytesPerWord - 1) = 0.
	endOfMemory := newEndOfMemory
]

{ #category : #'header access' }
ObjectMemory >> setHashBitsOf: oop to: hash [
	self longAt: oop
		put: (((self baseHeader: oop) bitAnd: HashBits bitInvert32)
				bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset)
]

{ #category : #initialization }
ObjectMemory >> setMemoryLimit: newMemoryLimit [
	self assert: (newMemoryLimit bitAnd: BytesPerWord - 1) = 0.
	memoryLimit := newMemoryLimit
]

{ #category : #'header access' }
ObjectMemory >> setSizeOfFree: chunk to: byteSize [
	"Set the header of the given chunk to make it be a free chunk of the given size."

	self longAt: chunk put: ((byteSize bitAnd: AllButTypeMask) bitOr: HeaderTypeFree).
]

{ #category : #allocation }
ObjectMemory >> shorten: obj toIndexableSize: nSlots [
	"Currently this works for pointer objects only, and is almost certainly wrong for 64 bits."
	| deltaBytes desiredLength fixedFields fmt hdr totalLength |
	(self isPointers: obj) ifFalse:
		[^obj].
	hdr := self baseHeader: obj.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: obj baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: obj format: fmt length: totalLength.
	desiredLength := fixedFields + nSlots.
	deltaBytes := (totalLength - desiredLength) * BytesPerWord.
	self setSizeOfFree: obj + BaseHeaderSize + (desiredLength * BytesPerWord)
		to: deltaBytes.
	(self headerType: obj) caseOf:	{
		[HeaderTypeSizeAndClass] ->
			[self longAt: obj put: hdr - deltaBytes].
		[HeaderTypeClass] ->
			[self longAt: obj put: ((hdr bitClear: SizeMask) bitOr: (hdr bitAnd: SizeMask) - deltaBytes)].
		[HeaderTypeShort] ->
			[self longAt: obj put: ((hdr bitClear: SizeMask) bitOr: (hdr bitAnd: SizeMask) - deltaBytes)] }.
	^obj
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

{ #category : #'header access' }
ObjectMemory >> sizeBitsOf: oop [
	"Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words."
	"Note: byte indexable objects need to have low bits subtracted from this size."

	| header |
	header := self baseHeader: oop.
	(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ ^ (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ ^ header bitAnd: SizeMask ].
]

{ #category : #'header access' }
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

	^ self longAt: oop - (BytesPerWord*2)
]

{ #category : #'header access' }
ObjectMemory >> sizeOfFree: oop [
	"Return the size of the given chunk in bytes. Argument MUST be a free chunk."

	^ (self longAt: oop) bitAnd: AllButTypeMask
]

{ #category : #'object format' }
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

{ #category : #'interpreter access' }
ObjectMemory >> splObj: index [
	<api>
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
		field := field - BytesPerWord.
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
	child := self longAt: field - BytesPerWord. "class word"
	child := child bitAnd: AllButTypeMask. "clear type bits"
	self longAt: field - BytesPerWord put: parentField.
	parentField := field - BytesPerWord bitOr: 1.
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
	"Return the start of object memory."

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

{ #category : #'interpreter access' }
ObjectMemory >> storeByte: byteIndex ofObject: oop withValue: valueByte [

	^ self byteAt: oop + BaseHeaderSize + byteIndex
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
	firstOut := outPointerArray + BaseHeaderSize.
	lastOut := firstOut - BytesPerWord.
	hdrBaseOut := outPointerArray + ((self lastPointerOf: outPointerArray) // (BytesPerWord*2) * BytesPerWord). "top half"

	lastSeg := segmentWordArray.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BytesPerWord.

	"Write a version number for byte order and version check"
	versionOffset := BytesPerWord.
	lastSeg := lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^PrimErrGenericFailure].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn := endSeg - ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*8) * BytesPerWord).  "Take 1/8 of seg"
	lastIn := firstIn - BytesPerWord.
	hdrBaseIn := firstIn + ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*16) * BytesPerWord). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: MarkBit).
	lastPtr := arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr := arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: MarkBit)].
		fieldPtr := fieldPtr + BytesPerWord].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart := youngStart.
	youngStart := self startOfMemory.  "process all of memory"
	self markAndTraceInterpreterOops.	"and special objects array"
	youngStart := savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: AllButMarkBit).
	fieldPtr := arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: AllButMarkBit)].
		fieldPtr := fieldPtr + BytesPerWord].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn := lastIn + BytesPerWord.
	(lastIn >= hdrBaseIn
	 or: [0 = (lastSeg := self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
		[lastIn := lastIn - BytesPerWord.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^self primitiveFailCodeAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop := self oopFromChunk: segmentWordArray + versionOffset + BaseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
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
						fieldPtr := fieldPtr + BytesPerWord]
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
							lastIn := lastIn + BytesPerWord.
							(lastIn >= hdrBaseIn
							or: [0 = (lastSeg := self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
								["Out of space in segment"
								lastIn := lastIn - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
							mapOop := (self longAt: fieldOop) bitAnd: AllButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut := lastOut + BytesPerWord.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut := lastOut - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
.							mapOop := lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + (BytesPerWord*2).
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + BytesPerWord]]].
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
		to: lastOut+BytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: lastOut+BytesPerWord
		put: outPointerArray + (self lastPointerOf: outPointerArray) - lastOut - extraSize + hdrTypeBits.
	self longAt: outPointerArray-extraSize
		put: lastOut - firstOut + (BytesPerWord*2) + hdrTypeBits.
	"Note that pointers have been stored into roots table"
	self beRootIfOld: outPointerArray.

	"Truncate the image segment..."
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastSeg+BytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: segmentWordArray-extraSize
		put: lastSeg - segmentWordArray + BaseHeaderSize + hdrTypeBits.
	self longAt: lastSeg+BytesPerWord
		put: endSeg - lastSeg - extraSize + hdrTypeBits.

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^PrimNoErr
]

{ #category : #'interpreter access' }
ObjectMemory >> storeLong32: fieldIndex ofObject: oop withValue: valueWord [

	^ self long32At: oop + BaseHeaderSize + (fieldIndex << 2)
		put: valueWord
]

{ #category : #'interpreter access' }
ObjectMemory >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."

	(self oop: oop isLessThan: youngStart) ifTrue: [
		self possibleRootStoreInto: oop value: valuePointer.
	].

	^ self longAt: oop + BaseHeaderSize + (fieldIndex << ShiftForWord)
		put: valuePointer
]

{ #category : #'interpreter access' }
ObjectMemory >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	"Like storePointer:ofObject:withValue:, but the caller guarantees that the
	 object being stored into is a young object or is already marked as a root."
	<api>
	<inline: true>
	^self
		longAt: oop + BaseHeaderSize + (fieldIndex << ShiftForWord)
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
	minFree := (lowSpaceThreshold + bytes + BaseHeaderSize + BytesPerWord - 1) bitAnd: (BytesPerWord - 1) bitInvert32.

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
	(format := self instSpecOfClass: classOop) < 8
		ifTrue:
			["indexable fields are words or pointers"
			size ~= 0 ifTrue:
				["fail if attempting to call new: on non-indexable class"
				 format < 2 ifTrue:
					[^false].
				 "fail if attempting to allocate over 2 Gb, since this overflows 32-bit arithmetic"
				 size >> (LongSizeNumBits - BytesPerWord) > 0 ifTrue:
					[^false]].
			allocSize := size * BytesPerWord]
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
	entriesAvailable := self fwdTableInit: BytesPerWord*2.
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
					(self isWeakNonInt: oop) ifTrue: [self finalizeReference: oop].
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

{ #category : #utilities }
ObjectMemory >> transfer: count from: src to: dst [ 
	| in out lastIn |
	<inline: true>
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	in := src - BytesPerWord.
	lastIn := in + (count * BytesPerWord).
	out := dst - BytesPerWord.
	[self oop: in isLessThan: lastIn]
		whileTrue: [self
				longAt: (out := out + BytesPerWord)
				put: (self longAt: (in := in + BytesPerWord))]
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
		field := field - BytesPerWord. "point at header"
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
	header := self longAt: field + BytesPerWord. "base header word"
	type := self rightType: header.
	self longAt: field put: (child bitOr: type). "install type on class oop"
	field := field + BytesPerWord. "point at header"
	"restore type bits"
	header := header bitAnd: AllButTypeMask.
	self longAt: field put: (header bitOr: type).
	"Effectively ^ Upward"
	true] whileTrue.
	^nil "for Slang..."
]

{ #category : #simulation }
ObjectMemory >> validate [
	"Validate all the objects in the heap.  This is a noop unless simulating, but is sent
	 so we need a null implementation when generating code."
	<cmacro: '() 0'>
	| oop prev |
	self interpreter transcript show: 'Validating...'.
	oop := self firstObject.
	[oop < endOfMemory] whileTrue: [
		self validate: oop.
		prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop.
	].
	prev := prev.  "Don't offer to delete this please"
	self interpreter transcript show: 'done.'; cr
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
		(self headerType: (nextChunk + (BytesPerWord*2))) = 0 ifFalse: [self halt]].
	(self headerType: nextChunk) = 1 ifTrue: [
		(self headerType: (nextChunk + BytesPerWord)) = 1 ifFalse: [self halt]].
	type = 2 ifTrue:
		["free block" ^ self].
	fmt := self formatOfHeader: header.
	cc := self compactClassIndexOfHeader: header.
	cc > 16 ifTrue: [self halt].	"up to 32 are legal, but not used"
	type = 0 ifTrue:
		["three-word header"
		((self longAt: oop-BytesPerWord) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-(BytesPerWord*2)) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-BytesPerWord) = type) ifTrue: [self halt].	"Class word is 0"
		sz = 0 ifFalse: [self halt]].
	type = 1 ifTrue:
		["two-word header"
		((self longAt: oop-BytesPerWord) bitAnd: 3) = type ifFalse: [self halt].
		cc > 0 ifTrue: [sz = 1 ifFalse: [self halt]].
		sz = 0 ifTrue: [self halt]].
	type = 3 ifTrue:
		["one-word header"
		cc = 0 ifTrue: [self halt]].
	fmt = 5 ifTrue: [self halt].
	fmt = 7 ifTrue: [self halt].
	fmt >= 12 ifTrue:
		["CompiledMethod -- check for integer header"
		(self isIntegerObject: (self longAt: oop + BytesPerWord)) ifFalse: [self halt]].
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
	<asmLabel: false> "prevent label duplication"
	| listOop listItemOop |

	
	listOop := self fetchPointer: 0 ofObject: oop.
	(self fetchClassOf: listOop) == (self splObj: ClassWeakFinalizer) ifTrue: [
		listItemOop := self fetchPointer: 0 ofObject: listOop.
		self storePointer: 1 ofObject: oop withValue: listItemOop. 
		self storePointer: 0 ofObject: listOop withValue: oop.
	].

]
