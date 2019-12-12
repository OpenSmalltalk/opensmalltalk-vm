"
InterpreterPrimitives implements most of the VM's core primitives.  It is the root of the interpreter hierarchy so as to share the core primitives amongst the varioius interpreters.

Instance Variables
	argumentCount			<Integer>
	ffiExceptionResponse		<Integer>
	inFFIFlags					<Integer>
	messageSelector			<Integer>
	newMethod					<Integer>
	nextProfileTick				<Integer>
	objectMemory				<ObjectMemory> (simulation only)
	preemptionYields			<Boolean>
	primFailCode				<Integer>
	osErrorCode				<Integer>
	profileMethod				<Integer>
	profileProcess				<Integer>
	profileSemaphore			<Integer>
	secHasEnvironmentAccess <Integer>

argumentCount
	- the number of arguments of the current message

ffiExceptionResponse
	- controls system response to exceptions during FFI calls.  See primitiveFailForFFIException:at:

inFFIFlags
	- flags recording currently only whether the system is in an FFI call

messageSelector
	- the oop of the selector of the current message

newMethod
	- the oop of the result of looking up the current message

nextProfileTick
	- the millisecond clock value of the next profile tick (if profiling is in effect)

objectMemory
	- the memory manager and garbage collector that manages the heap

preemptionYields
	- a boolean controlling the process primitives.  If true (old, incorrect, blue-book semantics) a preempted process is sent to the back of its run-queue.  If false, a process preempted by a higher-priority process is put back at the head of its run queue, hence preserving cooperative scheduling within priorities.

primFailCode
	- primitive success/failure flag, 0 for success, otherwise the reason code for failure

osErrorCode
	- a 64-bit value settable by external primitives conveying arbitrary error codes from the operating system and/or system libraries

profileMethod
	- the oop of the method at the time nextProfileTick was reached

profileProcess
	- the oop of the activeProcess at the time nextProfileTick was reached

profileSemaphore
	- the oop of the semaphore to signal when nextProfileTick is reached

secHasEnvironmentAccess
	- the function to call to check if access to the envronment should be granted to primitiveGetenv

"
Class {
	#name : #InterpreterPrimitives,
	#superclass : #VMClass,
	#instVars : [
		'objectMemory',
		'messageSelector',
		'argumentCount',
		'newMethod',
		'primFailCode',
		'osErrorCode',
		'exceptionPC',
		'inFFIFlags',
		'profileMethod',
		'profileProcess',
		'profileSemaphore',
		'nextProfileTick',
		'preemptionYields',
		'newFinalization',
		'sHEAFn',
		'ffiExceptionResponse'
	],
	#classVars : [
		'CrossedX',
		'EndOfRun',
		'MillisecondClockMask'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #'C translation' }
InterpreterPrimitives class >> declareCVarsIn: aCCodeGen [
	aCCodeGen
		var: 'osErrorCode' type: #sqLong;
		var: 'exceptionPC' type: #usqInt;
		var: 'sHEAFn' declareC: 'int (*sHEAFn)() = 0' "the hasEnvironmentAccess function"
]

{ #category : #'C translation' }
InterpreterPrimitives class >> defineAtCompileTime: anObject [
	"Override to define at translation time those variables that need to
	 be defined at compile time only in plugins, but not in the main VM,
	 because the VM generated is specific to these varables."
	anObject isSymbol ifFalse:
		[^false].
	(#(STACKVM COGVM COGMTVM SPURVM) includes: anObject) ifTrue:
		[^false].
	^VMBasicConstants namesDefinedAtCompileTime includes: anObject
]

{ #category : #'class initialization' }
InterpreterPrimitives class >> initializeMiscConstants [
	"Initialize the hashMultiply constants."
	super initializeMiscConstants.
	HashMultiplyConstant := 1664525.
	HashMultiplyMask := 16rFFFFFFF "(2 raisedTo: 28) - 1"
]

{ #category : #'primitive support' }
InterpreterPrimitives >> asUnsigned: anInteger [
	<inline: true>
	^self cCode: [anInteger asUnsignedInteger] inSmalltalk: [anInteger bitAnd: objectMemory maxCInteger]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> cStringOrNullFor: oop [
	"Answer either a malloced string with the null-terminated contents of oop if oop is a string,
	 or the null pointer if oop is nil, or fail.  It is the client's responsibility to free the string later."
	<api>
	<returnTypeC: #'char *'>
	<inline: false>
	| isString len cString |
	<var: 'cString' type: #'char *'>
	isString := self isInstanceOfClassByteString: oop.
	isString ifFalse:
		[oop ~= objectMemory nilObject ifTrue:
			[self primitiveFailFor: PrimErrBadArgument].
		 ^0].
	len := objectMemory lengthOf: oop.
	len = 0 ifTrue:
		[^0].
	cString := self malloc: len + 1.
	cString ifNil:
		[self primitiveFailFor: PrimErrNoCMemory.
		 ^0].
	self memcpy: cString _: (objectMemory firstIndexableField: oop) _: len.
	cString at: len put: 0.
	^cString
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> canBeImmutable: oop [
	<option: #IMMUTABILITY>
	| scheduler processLists |
	
	self assert: (objectMemory isNonImmediate: oop).
	
	"For now we fail the primitive for contexts to we ensure there are no immutable contexts.
	Later we can consider having immutable contexts and send cannotReturn callback
	when returning to an immutable context. That would mean that setting a context 
	to immutable would require a divorce and returns to immutable context are 
	necessarily across stack pages"
	(objectMemory isContext: oop) ifTrue: [ ^ false ].
	
	"Weak structures can't be immutable"
	(objectMemory isEphemeron: oop) ifTrue: [^ false].
	(objectMemory isWeakNonImm: oop) ifTrue: [^ false].
	
	"No clue what is going on for semaphores so they can't be immutable"
	(objectMemory isSemaphoreObj: oop) ifTrue: [^ false].
	
	"Simple version of process management: we forbid Process and LinkedList instances to be immutable 
	 as well as the Processor and the array of activeProcess"
	scheduler := self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: scheduler.
	oop = scheduler ifTrue: [ ^ false ].
	oop = processLists ifTrue: [ ^ false ].
	"Is it a linkedList ?"
	(objectMemory classIndexOf: (objectMemory fetchPointer: 1 ofObject: processLists)) = (objectMemory classIndexOf: oop) ifTrue: [ ^ false ].
	"is it a Process ?"
	(objectMemory classIndexOf: (objectMemory fetchPointer: ActiveProcessIndex ofObject: scheduler)) =  (objectMemory classIndexOf: oop) ifTrue: [ ^ false ].
	
	"The rest of the code is relative to process management: the Processor (the active 
	process scheduler) can't be immutable, as well as all the objects relative to Process management "
	"scheduler := self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: scheduler.
	((objectMemory formatOf: oop) = objectMemory nonIndexablePointerFormat)
		ifFalse: 
			[ (objectMemory isArrayNonImm: oop) ifFalse: [ ^ true ].
			  ^ (oop = processLists) not ].
	(objectMemory numSlotsOf: oop) >= 2 ifFalse: [ ^ true ].
	""is the oop the scheduler itself ?""
	oop = scheduler ifTrue: [ ^ false ].
	1 to: (objectMemory numSlotsOf: processLists) do: [ :i |
		""is the oop one of the linked lists ?""
		(list := processLists at: i) = oop ifTrue: [^ false].
		""is the oop one of the runnable process ?""
		first := objectMemory fetchPointer: FirstLinkIndex ofObject: list.
		first = objectMemory nilObject ifFalse: 
			[ last := objectMemory fetchPointer: LastLinkIndex ofObject: list.
			  link := first.
			  [ link = last ] whileFalse: 
				[ link = oop ifTrue: [ ^ false ]. 
				  link := objectMemory fetchPointer: NextLinkIndex ofObject: link. ] ] ]."
	^ true
]

{ #category : #'primitive support' }
InterpreterPrimitives >> failed [
	<api>
	<inline: true>
	"In C, non-zero is true, so avoid computation by simply answering primFailCode in the C version."
	^self cCode: [primFailCode] inSmalltalk: [primFailCode ~= 0]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> floatExponentBits [
	"Answer the number of bits in the double-precision exponent.  This is an 11-bit field."
	<inline: true>
	^11
]

{ #category : #'simulation support' }
InterpreterPrimitives >> getenv: aByteStringOrByteArray [
	<doNotGenerate>
	"The primitiveGetenv: primitive answers nil for undefined variables.
	 The primitiveGetenv implementation is written to expect getenv: to
	 answer 0, not nil,  for undefined variables.  Map nil to 0 for simulation."

	"aByteStringOrByteArray is probably null terminated, convert to non-null-terminated"
	^(self primitiveGetenv: (self asString: aByteStringOrByteArray)) ifNil: [0]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> initPrimCall [
	"Set the failure code/success flag in preparation for calling a primitve.
	 If primFailCode is non-zero a primitive has failed.  If primFailCode is
	 greater than one then its value indicates the reason for failure."
	<inline: true>
	primFailCode := 0
]

{ #category : #initialization }
InterpreterPrimitives >> initialize [
	"Here we can initialize the variables C initializes to zero.  #initialize methods do /not/ get translated."
	argumentCount := primFailCode := nextProfileTick := osErrorCode := exceptionPC := inFFIFlags := ffiExceptionResponse := 0.
	newFinalization := false
]

{ #category : #initialization }
InterpreterPrimitives >> initializeInterpreter: bytesToShift [
	sHEAFn := self ioLoadFunction: 'secHasEnvironmentAccess' From: 'SecurityPlugin'
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> isAppropriateForCopyObject: oop [
	^objectMemory isPointersNonImm: oop
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isDirectAlien: oop [
	^(self sizeFieldOfAlien: oop) > 0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isFinite: aDouble [
	<var: #aDouble type: #double>
	<inline: true>
	^aDouble - aDouble = 0.0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isIndirectAlien: oop [
	^(self sizeFieldOfAlien: oop) < 0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isInstanceOfClassArray: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassArray) is expanded in-place and
	 is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassArray) 
		compactClassIndex: ClassArrayCompactIndex
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isInstanceOfClassBlockClosure: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassBlockClosure) is expanded in-place
	 and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassBlockClosure) 
		compactClassIndex: ClassBlockClosureCompactIndex
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isInstanceOfClassByteString: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassByteString) is expanded in-place and
	 is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassByteString) 
		compactClassIndex: ClassByteStringCompactIndex
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isNegativeIntegerValueOf: oop [
	"Answer true if integer object is negative.
	Fail if object pointed by oop i not an integer."
	| ok smallInt |

	(objectMemory isIntegerObject: oop) ifTrue:
		[smallInt := objectMemory integerValueOf: oop.
		^smallInt < 0].
	
	(objectMemory isNonIntegerNonImmediate: oop) ifTrue:
		[ok := objectMemory isClassOfNonImm: oop
						equalTo: (objectMemory splObj: ClassLargePositiveInteger)
						compactClassIndex: ClassLargePositiveIntegerCompactIndex.
		 ok ifTrue: [^false].
			
		 ok := objectMemory isClassOfNonImm: oop
								equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
								compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
		 ok ifTrue: [^true]].
	self primitiveFail.
	^false
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isPointerAlien: oop [
	^(self sizeFieldOfAlien: oop) = 0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isPositiveMachineIntegerObject: oop [
	"Answer if oop is a value of an integer in address range, i.e up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargePositiveInteger of size <= word size."
	| ok |
	(objectMemory isIntegerObject: oop) ifTrue:
		[^(objectMemory integerValueOf: oop) >= 0].

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[^false].

	ok := objectMemory
			isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	^ok and: [(objectMemory numBytesOfBytes: oop) <= (self sizeof: #'usqIntptr_t')]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isSignedInteger: integer inRangeForBits: nBits [
	"Answer if integer will fit within a variable of nBits, where nBits is 8, 16, 32 or 64.
	 Signed shift right by nBits - 1 to map in-range values to either 0 or -1.
	 Add one to map in-range values to 0 or 1.
	 Perform an unsigned comparison for greater than 1 to eliminate values out of range."
	<inline: true>
	^self cCode: [(self asUnsigned: (integer signedBitShift: 1 - nBits) + 1) <= 1]
		inSmalltalk: [((integer bitShift: 1 - nBits) + 1 bitAnd: objectMemory maxCInteger) <= 1]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> magnitude64BitIntegerFor: magnitude neg: isNegative [
	"Return a Large Integer object for the given integer magnitude and sign"
	| newLargeInteger largeClass highWord sz isSmall smallVal |
	<var: 'magnitude' type: #usqLong>
	<var: 'highWord' type: #usqInt>

	isSmall := isNegative
				ifTrue: [magnitude <= (objectMemory maxSmallInteger + 1)]
				ifFalse: [magnitude <= objectMemory maxSmallInteger].
	isSmall ifTrue:
		[smallVal := self cCoerceSimple: magnitude to: #sqInt.
		 isNegative ifTrue: [smallVal := 0 - smallVal].
		 ^objectMemory integerObjectOf: smallVal].

	largeClass := isNegative
					ifTrue: [objectMemory classLargeNegativeInteger]
					ifFalse: [objectMemory classLargePositiveInteger].
	objectMemory wordSize = 8
		ifTrue: [sz := 8]
		ifFalse:
			[(highWord := magnitude >> 32) = 0
				ifTrue: [sz := 4] 
				ifFalse:
					[sz := 5.
					 (highWord := highWord >> 8) = 0 ifFalse:
						[sz := sz + 1.
						 (highWord := highWord >> 8) = 0 ifFalse:
							[sz := sz + 1.
							 (highWord := highWord >> 8) = 0 ifFalse: [sz := sz + 1]]]]].
	newLargeInteger := objectMemory instantiateClass: largeClass indexableSize:  sz.
	SPURVM
		ifTrue:
			["Memory is eight byte aligned in SPUR, so we are sure to have room for 64bits word whatever allocated sz"
			objectMemory storeLong64: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped64IfBigEndian: magnitude)]
		ifFalse:
			[sz > 4
				ifTrue: [objectMemory storeLong64: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped64IfBigEndian: magnitude)]
				ifFalse: [objectMemory storeLong32: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped32IfBigEndian: magnitude)]].

	^newLargeInteger
]

{ #category : #'primitive support' }
InterpreterPrimitives >> magnitude64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or an eight-byte LargeInteger."
	| sz value ok smallIntValue |
	<returnTypeC: #usqLong>
	<var: #value type: #usqLong>

	(objectMemory isIntegerObject: oop) ifTrue:
		[smallIntValue := (objectMemory integerValueOf: oop).
		smallIntValue < 0 ifTrue: [smallIntValue := 0 - smallIntValue].
		^self cCoerce: smallIntValue to: #usqLong].

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[self primitiveFail.
		 ^0].

	ok := objectMemory isClassOfNonImm: oop
					equalTo: (objectMemory splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok
		ifFalse:
			[ok := objectMemory isClassOfNonImm: oop
							equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
			ok ifFalse:
				[self primitiveFail.
				 ^0]].
	sz := objectMemory numBytesOfBytes: oop.
	sz > (self sizeof: #sqLong) ifTrue:
		[self primitiveFail.
		 ^0].

	"self cppIf: SPURVM
		ifTrue:
			[""Memory is 8 byte aligned in Spur and oversized bytes are set to zero, so we can safely fetch 8 bytes""
			value := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
		ifFalse:
			["sz > 4
				ifTrue: [value := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
				ifFalse: [value := self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int']"]".
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> maybeInlinePositive32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or a four-byte LargePositiveInteger."
	<notOption: #Spur64BitMemoryManager>
	<returnTypeC: #'unsigned int'>
	| value ok sz |
	(objectMemory isIntegerObject: oop) ifTrue:
		[value := objectMemory integerValueOf: oop.
		 (value < 0) ifTrue:
			[self primitiveFail. value := 0].
		 ^value].

	(objectMemory isNonIntegerImmediate: oop)
		ifTrue:
			[self primitiveFail.
			 ^0]
		ifFalse:
			[ok := objectMemory
					isClassOfNonImm: oop
					equalTo: (objectMemory splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
			ok ifFalse:
				[self primitiveFail.
				 ^0].
			sz := objectMemory numBytesOfBytes: oop.
			sz > 4 ifTrue:
				[self primitiveFail.
				 ^0].
			^self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int']
]

{ #category : #'primitive support' }
InterpreterPrimitives >> noInlineSigned32BitValueGutsOf: oop [
	"Convert the given object into an integer value.
	The object may be a four-byte LargeInteger."
	| value negative ok magnitude |
	<notOption: #Spur64BitMemoryManager>
	<inline: false>
	<returnTypeC: #int>
	<var: #value type: #int>
	<var: #magnitude type: #'unsigned int'>
	self deny: objectMemory hasSixtyFourBitImmediates.
	self deny: (objectMemory isIntegerObject: oop).

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[self primitiveFail.
		 ^0].

	ok := objectMemory
			isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok
		ifTrue: [negative := false]
		ifFalse:
			[negative := true.
			 ok := objectMemory isClassOfNonImm: oop
							equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
			 ok ifFalse:
				[self primitiveFail.
				 ^0]].
	(objectMemory numBytesOfBytes: oop) > 4 ifTrue:
		[^self primitiveFail].

	magnitude := self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int'.

	(negative
		ifTrue: [magnitude > 16r80000000]
		ifFalse: [magnitude >= 16r80000000])
			ifTrue:
				[self primitiveFail.
				^0].
	negative
		ifTrue: [value := 0 - magnitude]
		ifFalse: [value := magnitude].
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> positive32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or a four-byte LargePositiveInteger."
	<returnTypeC: #'unsigned int'>
	objectMemory hasSixtyFourBitImmediates
		ifTrue:
			[(objectMemory isIntegerObject: oop) ifTrue:
				[| value64 |
				value64 := objectMemory integerValueOf: oop.
				 (value64 < 0
		 			 or: [self cCode: [(self cCoerceSimple: value64 to: #'unsigned int') ~= value64]
							inSmalltalk: [value64 >> 32 ~= 0]]) ifTrue:
						[self primitiveFail. value64 := 0].
				 ^value64].
			self primitiveFail.
			^0]
		ifFalse:
			[^self maybeInlinePositive32BitValueOf: oop]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> positive64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or an eight-byte LargePositiveInteger."

	<returnTypeC: #usqLong>
	| sz value ok |
	<var: #value type: #usqLong>
	(objectMemory isIntegerObject: oop) ifTrue:
		[(objectMemory integerValueOf: oop) < 0 ifTrue:
			[^self primitiveFail].
		 ^objectMemory integerValueOf: oop].

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[self primitiveFail.
		 ^0].

	ok := objectMemory
			isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok ifFalse:
		[self primitiveFail.
		 ^0].
	sz := objectMemory numBytesOfBytes: oop.
	sz > (self sizeof: #sqLong) ifTrue:
		[self primitiveFail.
		 ^0].

	"self cppIf: SPURVM
		ifTrue:
			[""Memory is 8 byte aligned in Spur and oversized bytes are set to zero, so we can safely fetch 8 bytes""
			value := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
		ifFalse:
			["sz > 4
				ifTrue: [value := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
				ifFalse: [value := self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int']"]".
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> positiveMachineIntegerValueOf: oop [
	"Answer a value of an integer in address range, i.e up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargePositiveInteger of size <= word size."
	<returnTypeC: #'usqIntptr_t'>
	<inline: true> "only two callers & one is primitiveNewWithArg"
	| value bs ok |
	(objectMemory isIntegerObject: oop) ifTrue:
		[value := objectMemory integerValueOf: oop.
		 value < 0 ifTrue: [^self primitiveFail].
		^value].

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[self primitiveFail.
		 ^0].

	ok := objectMemory
			isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok ifFalse:
		[self primitiveFail.
		 ^0].
	bs := objectMemory numBytesOfBytes: oop.
	bs > (self sizeof: #'usqIntptr_t') ifTrue:
		[self primitiveFail.
		 ^0].

	"self cppIf: SPURVM
		ifTrue: [""Memory is 8 byte aligned in Spur and oversized bytes are set to zero, so we can safely fetch 8 bytes""
			^objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
		ifFalse: ["((self sizeof: #'usqIntptr_t') = 8
			and: [bs > 4])
				ifTrue:
					[^objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
				ifFalse:
					[^self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int']"]"
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveAdd [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) + (self stackIntegerValue: 0)
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveAddLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| a b result oopResult aIsNegative bIsNegative resultIsNegative oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	self successful ifFalse:[^nil].
	(aIsNegative = bIsNegative)
		ifTrue:
			["Protect against overflow"
			a > (16rFFFFFFFFFFFFFFFF - b) ifTrue: [self primitiveFail. ^nil].
			result := a + b.
			resultIsNegative := aIsNegative]
		ifFalse:
			[(a >= b)
				ifTrue:
					[result := a - b.
					resultIsNegative := aIsNegative]
				ifFalse:
					[result := b - a.
					resultIsNegative := bIsNegative]].
	oopResult := self magnitude64BitIntegerFor: result neg: resultIsNegative.
	self successful ifTrue:[self pop: 2 thenPush: oopResult].
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveAdoptInstance [
	"Primitive. Change the class of the argument to make it an instance of the receiver
	 given that the format of the receiver matches the format of the argument's class.
	 Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a
	 compact class and the argument isn't, or when the argument's class is compact and
	 the receiver isn't, or when the format of the receiver is different from the format of
	 the argument's class, or when the arguments class is fixed and the receiver's size
	 differs from the size that an instance of the argument's class should have."
	| rcvr arg err |

	arg := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isImmediate: arg)
	 or: [argumentCount > 1
		and: [(objectMemory isImmediate: rcvr)
			or: [(self objCouldBeClassObj: rcvr) not]]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].

	err := objectMemory changeClassOf: arg to: rcvr.
	err = 0
		ifTrue:
			["Flush at cache because rcvr's class has changed."
			 self flushAtCache.
			 self pop: self methodArgumentCount]
		ifFalse:
			["changeClassOf:to: answers errors as if rcvr (the class) is an argument..."
			 err = PrimErrBadReceiver
				ifTrue:
					[err := PrimErrBadArgument]
				ifFalse:
					[err = PrimErrBadArgument ifTrue:
						[err := PrimErrBadReceiver]].
			 self primitiveFailFor: err].
	^nil
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveAllInstances [
	"Answer an array of all instances of the receiver that exist
	 when the primitive is called, excluding any that may be
	 garbage collected as a side effect of allocating the result array."

	<export: true>
	| result |
	NewspeakVM ifTrue: "For the mirror prims check that the class obj is actually a valid class."
		[(argumentCount < 1
		  or: [(objectMemory isNonImmediate: self stackTop)
			  and: [self objCouldBeClassObj: self stackTop]]) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument]].
	result := objectMemory allInstancesOf: self stackTop.
	(objectMemory isIntegerObject: result) ifTrue:
		[objectMemory growToAccomodateContainerWithNumSlots: (objectMemory integerValueOf: result).
		 result := objectMemory allInstancesOf: self stackTop.
		 (objectMemory isIntegerObject: result) ifTrue:
			[^self primitiveFailFor: PrimErrNoMemory]].
	self pop: argumentCount+1 thenPush: result
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveAllObjects [
	"Answer an array of all objects that exist when the primitive
	 is called, excluding those that may be garbage collected as
	 a side effect of allocating the result array."

	<export: true>
	| result |
	result := objectMemory allObjects.
	(objectMemory isIntegerObject: result) ifTrue:
		[objectMemory growToAccomodateContainerWithNumSlots: (objectMemory integerValueOf: result).
		 result := objectMemory allObjects.
		 (objectMemory isIntegerObject: result) ifTrue:
			[^self primitiveFailFor: PrimErrNoMemory]].
	self pop: argumentCount+1 thenPush: result
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveArctan [
	"N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		[self stackTopPut: (objectMemory floatObjectOf:
								(self cCode: [rcvr atan]
									inSmalltalk: [rcvr = rcvr
													ifTrue: [rcvr arcTan]
													ifFalse: [Float nan]]))]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveArrayBecome [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := objectMemory become: rcvr with: arg twoWay: true copyHash: false.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveArrayBecomeOneWay [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := objectMemory become: rcvr with: arg twoWay: false copyHash: true.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveArrayBecomeOneWayCopyHash [
	"Similar to primitiveArrayBecomeOneWay but accepts a third argument deciding whether to
	 copy the receiver's elements identity hashes over the argument's elements identity hashes."

	| copyHashFlag ec |
	self stackTop = objectMemory trueObject
		ifTrue: [copyHashFlag := true]
		ifFalse:
			[self stackTop = objectMemory falseObject
				ifTrue: [copyHashFlag := false]
				ifFalse:
					[self primitiveFailFor: PrimErrBadArgument.
					 ^nil]].
	ec := objectMemory
			become: (self stackValue: 2)
			with: (self stackValue: 1)
			twoWay: false
			copyHash: copyHashFlag.
	ec = PrimNoErr
		ifTrue: [self pop: argumentCount]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveArrayBecomeOneWayNoCopyHash [
	"Similar to primitiveArrayBecomeOneWay but does /not/ copy the receiver's
	 elements identity hashes over the argument's elements identity hashes."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := objectMemory become: rcvr with: arg twoWay: false copyHash: false.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveAsCharacter [
	| characterCode characterObject |
	characterCode := self stackTop.
	((objectMemory isIntegerObject: characterCode)
	and: [characterCode := objectMemory integerValueOf: characterCode.
		objectMemory isInRangeCharacterCode: characterCode]) ifFalse:
		[^self primitiveFailFor: (argumentCount = 0
									ifTrue: [PrimErrBadReceiver]
									ifFalse: [PrimErrBadArgument])].
	characterObject := self characterForAscii: characterCode.
	self pop: argumentCount + 1 thenPush: characterObject
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveAsFloat [
	"N.B. This will answer inexact results for integers with > 53 bits of magnitude."
	| rcvr |
	rcvr := self stackTop.
	self assert: (objectMemory isIntegerObject: rcvr).
	self pop: 1 thenPushFloat: (objectMemory integerValueOf: rcvr) asFloat
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveAt [
	<accessorDepth: 0>
	self commonAt: false
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveAtPut [
	<accessorDepth: 0>
	self commonAtPut: false
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveBeCursor [
	"Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk."

	| cursorObj maskBitsIndex maskObj bitsObj extentX extentY depth offsetObj offsetX offsetY cursorBitsIndex ourCursor |

	argumentCount = 0 ifTrue: [
		cursorObj := self stackTop.
		maskBitsIndex := nil].
	argumentCount = 1 ifTrue: [
		cursorObj := self stackValue: 1.
		maskObj := self stackTop].
	self success: argumentCount < 2.

	self successful ifTrue: [
		self success: ((objectMemory isPointers: cursorObj) and: [(objectMemory lengthOf: cursorObj) >= 5])].
	self successful ifTrue: [
		bitsObj := objectMemory fetchPointer: 0 ofObject: cursorObj.
		extentX := self fetchInteger: 1 ofObject: cursorObj.
		extentY := self fetchInteger: 2 ofObject: cursorObj.
		depth := self fetchInteger: 3 ofObject: cursorObj.
		offsetObj := objectMemory fetchPointer: 4 ofObject: cursorObj.
		self success: ((objectMemory isPointers: offsetObj) and: [(objectMemory lengthOf: offsetObj) >= 2])].

	self successful ifTrue: [
		offsetX := self fetchInteger: 0 ofObject: offsetObj.
		offsetY := self fetchInteger: 1 ofObject: offsetObj.
		(argumentCount = 0 and: [depth = 32])
			ifTrue: [
				"Support arbitrary-sized 32 bit ARGB forms --bf 3/1/2007 23:51"
				self success: ((extentX > 0) and: [extentY > 0]).
				self success: ((offsetX >= (extentX * -1)) and: [offsetX <= 0]).
				self success: ((offsetY >= (extentY * -1)) and: [offsetY <= 0]).
				self success: ((objectMemory isWords: bitsObj) and: [(objectMemory lengthOf: bitsObj) = (extentX * extentY)]).
				cursorBitsIndex := bitsObj + objectMemory baseHeaderSize.
				self cCode: '' inSmalltalk:
					[ourCursor := Cursor
						extent: extentX @ extentY
						depth: 32
						fromArray: ((1 to: extentX * extentY) collect: [:i |
							objectMemory fetchLong32: i-1 ofObject: bitsObj])
						offset: offsetX  @ offsetY]]
			ifFalse: [
				self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
				self success: ((offsetX >= -16) and: [offsetX <= 0]).
				self success: ((offsetY >= -16) and: [offsetY <= 0]).
				self success: ((objectMemory isWords: bitsObj) and: [(objectMemory lengthOf: bitsObj) = 16]).
				cursorBitsIndex := bitsObj + objectMemory baseHeaderSize.
				self cCode: '' inSmalltalk:
					[ourCursor := Cursor
						extent: extentX @ extentY
						fromArray: ((1 to: 16) collect: [:i |
							((objectMemory fetchLong32: i-1 ofObject: bitsObj) >> (objectMemory wordSize*8 - 16)) bitAnd: 16rFFFF])
						offset: offsetX  @ offsetY]]].

	argumentCount = 1 ifTrue: [
		self success: ((objectMemory isPointers: maskObj) and: [(objectMemory lengthOf: maskObj) >= 5]).
		self successful ifTrue: [
			bitsObj := objectMemory fetchPointer: 0 ofObject: maskObj.
			extentX := self fetchInteger: 1 ofObject: maskObj.
			extentY := self fetchInteger: 2 ofObject: maskObj.
			depth := self fetchInteger: 3 ofObject: maskObj].

		self successful ifTrue: [
			self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
			self success: ((objectMemory isWords: bitsObj) and: [(objectMemory lengthOf: bitsObj) = 16]).
			maskBitsIndex := bitsObj + objectMemory baseHeaderSize]].

	self successful ifTrue: [
		argumentCount = 0
			ifTrue: [
				depth = 32
					ifTrue: [(self cCode: 'ioSetCursorARGB(cursorBitsIndex, extentX, extentY, offsetX, offsetY)'
						inSmalltalk: [ourCursor show. Cursor currentCursor == ourCursor])	
							ifFalse: [^self success: false]]
					ifFalse: [self cCode: 'ioSetCursor(cursorBitsIndex, offsetX, offsetY)'
						inSmalltalk: [ourCursor show]]]
			ifFalse: [self cCode: 'ioSetCursorWithMask(cursorBitsIndex, maskBitsIndex, offsetX, offsetY)'
						inSmalltalk: [cursorBitsIndex == maskBitsIndex. "placate compiler"
									ourCursor show]].
		self pop: argumentCount]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveBeDisplay [
	"Record the system Display object in the specialObjectsTable,
	 and if possible pin the display bitmap.  Further, invoke ioBeDisplay
	 to alow the VM to record the location, width heigth & depth of the bitmap."
	| rcvr bitsOop depthOop heightOop widthOop |
	rcvr := self stackTop.
	((objectMemory isPointers: rcvr)
	and: [(objectMemory lengthOf: rcvr) >= 4
	and: [bitsOop := objectMemory fetchPointer: 0 ofObject: rcvr.
		((objectMemory isWordsOrBytes: bitsOop)
		or: [objectMemory isIntegerObject: bitsOop]) "for surface plugin handles"
	and: [(objectMemory isIntegerObject: (widthOop := objectMemory fetchPointer: 1 ofObject: rcvr))
	and: [(objectMemory isIntegerObject: (heightOop := objectMemory fetchPointer: 2 ofObject: rcvr))
	and: [(objectMemory isIntegerObject: (depthOop := objectMemory fetchPointer: 3 ofObject: rcvr))]]]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadReceiver].
	objectMemory splObj: TheDisplay put: rcvr.
	(objectMemory hasSpurMemoryManagerAPI
	 and: [(objectMemory isNonImmediate: bitsOop)
	 and: [(objectMemory isPinned: bitsOop) not]]) ifTrue:
		[rcvr := objectMemory pinObject: bitsOop. "Answers 0 if memory required to pin bit not enough memory available."
		 rcvr ~= 0 ifTrue: [bitsOop := rcvr]].
	self ioBeDisplay: ((objectMemory isNonImmediate: bitsOop)
						ifTrue: [objectMemory firstIndexableField: bitsOop]
						ifFalse: [bitsOop asVoidPointer])
		width: (objectMemory integerValueOf: widthOop)
		height: (objectMemory integerValueOf: heightOop)
		depth: (objectMemory integerValueOf: depthOop)
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveBeep [
"make the basic beep noise"
	self ioBeep.
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveBehaviorHash [
	| hashOrError |
	NewspeakVM ifTrue: "For the mirror prims check that the class obj is actually a valid class."
		[argumentCount > 0 ifTrue:
			[((objectMemory isNonImmediate: self stackTop)
			  and: [self objCouldBeClassObj: self stackTop]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument]]].
	self assert: ((objectMemory isNonImmediate: self stackTop)
				  and: [self addressCouldBeClassObj: self stackTop]).
	hashOrError := objectMemory ensureBehaviorHash: self stackTop.
	hashOrError >= 0
		ifTrue: [self pop: argumentCount + 1 thenPushInteger: hashOrError]
		ifFalse: [self primitiveFailFor: hashOrError negated]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitAnd [
	<inline: false>
	<var: 'integerArgumentValue' type: #usqInt>
	<var: 'integerReceiverValue' type: #usqInt>
	| integerArgumentValue integerReceiverValue |
	"Note no short-cut for SmallIntegers.  Either the inline interpreter bytecode or the JIT primitive will handle this case."
	integerArgumentValue := self positiveMachineIntegerValueOf: self stackTop.
	integerReceiverValue := self positiveMachineIntegerValueOf: (self stackValue: 1).
	self successful ifTrue:
		[self pop: 2 thenPush: (self positiveMachineIntegerFor: (integerArgumentValue bitAnd: integerReceiverValue))]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitAndLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'usqLong'>
	<var: 'integerArg' type: 'usqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitAnd: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitOr [
	<inline: false>
	<var: 'integerArgumentValue' type: #usqInt>
	<var: 'integerReceiverValue' type: #usqInt>
	| integerArgumentValue integerReceiverValue |
	"Note no short-cut for SmallIntegers.  Either the inline interpreter bytecode or the JIT primitive will handle this case."
	integerArgumentValue := self positiveMachineIntegerValueOf: self stackTop.
	integerReceiverValue := self positiveMachineIntegerValueOf: (self stackValue: 1).
	self successful ifTrue:
		[self pop: 2 thenPush: (self positiveMachineIntegerFor: (integerArgumentValue bitOr: integerReceiverValue))]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitOrLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'usqLong'>
	<var: 'integerArg' type: 'usqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitOr: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitShift [
	"Perform a bitShift.  In 32-bits deal only with non-negative 32-bit integers.
	  In 64-bits deal with signed 64-bit quantities (max (2^63)-1)."
	| integerReceiver integerArgument shifted |
	<var: #integerReceiver type: #sqInt>
	integerArgument := self stackTop.
	(objectMemory isIntegerObject: integerArgument) ifFalse:
		[^self primitiveFail].
	integerReceiver := self stackValue: 1.
	objectMemory wordSize = 4
		ifTrue:
			[integerReceiver := self positive32BitValueOf: integerReceiver]
		ifFalse:
			[integerReceiver := self signed64BitValueOf: integerReceiver].
	self successful ifTrue:
		[(integerArgument := objectMemory integerValueOf: integerArgument) >= 0
			ifTrue: "Left shift -- must fail bits would be lost"
				[integerArgument <= objectMemory numSmallIntegerBits ifFalse:
					[^self primitiveFail].
				shifted := integerReceiver << integerArgument.
				self cCode: '' inSmalltalk: [shifted := objectMemory wordSize = 4
									ifTrue: [shifted signedIntFromLong]
									ifFalse: [shifted signedIntFromLong64]].
				integerReceiver = (objectMemory wordSize = 4
									ifTrue: [shifted >> integerArgument]
									ifFalse: [shifted >>> integerArgument]) ifFalse:
					[^self primitiveFail]]
			ifFalse: "Right shift -- OK to lose bits"
				[integerArgument >= objectMemory numSmallIntegerBits negated ifFalse:
					[^self primitiveFail].
				 shifted := objectMemory wordSize = 4
								ifTrue: [integerReceiver >> (0 - integerArgument)]
								ifFalse: [integerReceiver >>> (0 - integerArgument)]].
		shifted := objectMemory wordSize = 4
					ifTrue: [self positive32BitIntegerFor: shifted]
					ifFalse:
						[(objectMemory isIntegerValue: shifted)
							ifTrue: [objectMemory integerObjectOf: shifted]
							ifFalse: [self signed64BitIntegerFor: shifted]].
		self pop: 2 thenPush: shifted]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitShiftLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| a shift result oopResult aIsNegative oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	shift := self stackIntegerValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	a := self magnitude64BitValueOf: oopRcvr.
	self successful ifFalse:[^nil].
	(shift >= 0)
		ifTrue:
			["Protect against overflow"
			result := 16rFFFFFFFFFFFFFFFF. "This is to avoid undue (usqInt) cast"
			(shift >= 64 or: [a > (result >> shift)]) ifTrue: [self primitiveFail. ^nil].
			result := a << shift]
		ifFalse:
			[shift := 0 - shift.
			shift >= 64
				ifTrue: [result := 0]
				ifFalse: [result := a >> shift].
			"Fake 2 complement for negative values"
			(aIsNegative and: [result << shift ~= a]) ifTrue: [result := result + 1]].
	oopResult := self magnitude64BitIntegerFor: result neg: aIsNegative.
	self successful ifTrue:[self pop: 2 thenPush: oopResult].
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitXor [
	<inline: false>
	<var: 'integerArgumentValue' type: #usqInt>
	<var: 'integerReceiverValue' type: #usqInt>
	| integerReceiver integerArgument integerArgumentValue integerReceiverValue |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	((objectMemory isIntegerObject: integerArgument)
	 and: [objectMemory isIntegerObject: integerReceiver])
		ifTrue: "xoring will leave the tag bits zero, whether the tag is 1 or zero, so add it back in."
			[self pop: 2 thenPush: (integerArgument bitXor: integerReceiver) + objectMemory smallIntegerTag]
		ifFalse:
			[integerArgumentValue := self positiveMachineIntegerValueOf: integerArgument.
			integerReceiverValue := self positiveMachineIntegerValueOf: integerReceiver.
			 self successful ifTrue:
				[self pop: 2 thenPush: (self positiveMachineIntegerFor: (integerArgumentValue bitXor: integerReceiverValue))]]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitXorLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'usqLong'>
	<var: 'integerArg' type: 'usqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitXor: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveBytesLeft [
	"Answer bytes available at this moment. For more meaningful 
	 results, calls to this primitive should be precedeed by a full 
	 or incremental garbage collection."
	| aBool |
	self methodArgumentCount = 0 ifTrue: "old behavior - just return the size of free memory"
		[^self pop: 1 thenPushInteger: objectMemory freeSize].
	self methodArgumentCount = 1 ifTrue:
		["Spur behavior; if argument is nil answer size of largest free chunk in oldSpace."
		(objectMemory hasSpurMemoryManagerAPI
		 and: [self stackTop = objectMemory nilObject]) ifTrue:
			[^self pop: 2 thenPushInteger: objectMemory sizeOfLargestFreeChunk].
		"new behaviour -including or excluding swap space depending on aBool"
		aBool := self booleanValueOf: self stackTop.
		self successful ifTrue:
			[^self pop: 2 thenPushInteger: (objectMemory bytesLeft: aBool)]].
	^self primitiveFail
]

{ #category : #'plugin primitives' }
InterpreterPrimitives >> primitiveCalloutToFFI [
	"Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec.
	Due to this we use the pluggable prim mechanism explicitly here
	(the first literal of any FFI spec'ed method is an ExternalFunction
	and not an array as used in the pluggable primitive mechanism)."

	| primitiveCallout |
	<var: #primitiveCallout declareC: 'void (*primitiveCallout)(void)'>
	primitiveCallout := self functionForPrimitiveCallout.
	primitiveCallout isNil
		ifTrue: [self primitiveFail]
		ifFalse: [self perform: primitiveCallout]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveChangeClass [
	"Primitive.  Change the class of the receiver into the class of the argument given that
	 the format of the receiver matches the format of the argument's class.  Fail if the
	 receiver or argument are SmallIntegers, or the receiver is an instance of a compact
	 class and the argument isn't, or when the argument's class is compact and the receiver
	 isn't, or when the format of the receiver is different from the format of the argument's
	 class, or when the arguments class is fixed and the receiver's size differs from the size
	 that an instance of the argument's class should have."
	| arg rcvr argClass err |
	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.
	self successful ifFalse:[^nil].
	argClass := objectMemory fetchClassOfNonImm: arg.
	err := objectMemory changeClassOf: rcvr to: argClass.
	err = 0
		ifTrue: ["Flush at cache because rcvr's class has changed."
				self flushAtCache.
				self pop: self methodArgumentCount]
		ifFalse: [self primitiveFailFor: err].
	^nil
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveClass [
	| instance |
	instance := self stackTop.
	(argumentCount > 0
	 and: [objectMemory isOopForwarded: instance])
		ifTrue:
			[self primitiveFail]
		ifFalse:
			[self pop: argumentCount + 1 thenPush: (objectMemory fetchClassOf: instance)]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveClearVMProfile [
	"Primitive. Void the VM profile histograms."
	self cCode: 'ioClearProfile()'.
	self pop: argumentCount
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveClipboardText [
	"When called with a single string argument, post the string to 
	the clipboard. When called with zero arguments, return a 
	string containing the current clipboard contents."
	| s sz |
	argumentCount = 1
		ifTrue:
			[s := self stackTop.
			 (objectMemory isBytes: s) ifFalse: [^ self primitiveFail].
			 self successful ifTrue:
				[sz := objectMemory numBytesOfBytes: s.
				 self clipboardWrite: sz From: s + objectMemory baseHeaderSize At: 0.
				 self pop: 1]]
		ifFalse:
			[sz := self clipboardSize.
			 objectMemory hasSpurMemoryManagerAPI
				ifTrue:
					[s := objectMemory allocateBytes: sz classIndex: ClassByteStringCompactIndex.
					 s ifNil: [^self primitiveFail]]
				ifFalse:
					[(objectMemory sufficientSpaceToAllocate: sz) ifFalse: [^self primitiveFail].
					 s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: sz].
			 self clipboardRead: sz Into: s + objectMemory baseHeaderSize At: 0.
			 self pop: 1 thenPush: s]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveClockLogAddresses [
	"Take a boolean which if true turns or keeps clock logging on.  Answer an array supplying
	 the size of the clock logs, the address of the usecs log, the index in it, the address of the
	 msecs log, and the index into it."
	<export: true>
	| result runInNOut usecs uidx msecs midx v1 v2 |
	<var: #usecs type: #'void *'>
	<var: #msecs type: #'void *'>
	<var: #runInNOut type: #sqInt> "bypass type inference which would deduce int"
	argumentCount ~= 1 ifTrue:
		[^self primitiveFail].
	runInNOut := (self stackValue: 0) == objectMemory trueObject.
	self ioGetClockLogSize: (self addressOf: runInNOut)
		Usecs: (self addressOf: usecs) Idx: (self addressOf: uidx)
		Msecs: (self addressOf: msecs) Idx: (self addressOf: midx).
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 5.
	result = 0 ifTrue:
		[^self primitiveFail].
	objectMemory pushRemappableOop: result.
	objectMemory storePointerUnchecked: 0 ofObject: objectMemory topRemappableOop withValue: (objectMemory integerObjectOf: runInNOut).
	v1 := self positive32BitIntegerFor: usecs asUnsignedInteger.
	v2 := self positive32BitIntegerFor: msecs asUnsignedInteger.
	self successful ifFalse:
		[objectMemory popRemappableOop.
		 ^self primitiveFail].
	objectMemory storePointer: 1 ofObject: objectMemory topRemappableOop withValue: v1.
	objectMemory storePointerUnchecked: 2 ofObject: objectMemory topRemappableOop withValue: (objectMemory integerObjectOf: uidx).
	objectMemory storePointer: 3 ofObject: objectMemory topRemappableOop withValue: v2.
	objectMemory storePointerUnchecked: 4 ofObject: objectMemory topRemappableOop withValue: (objectMemory integerObjectOf: midx).
	self pop: 2 thenPush: objectMemory popRemappableOop

]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveClone [
	"Return a shallow copy of the receiver."

	| rcvr newCopy |
	rcvr := self stackTop.
	(objectMemory isImmediate: rcvr)
		ifTrue:
			[newCopy := rcvr]
		ifFalse:
			[(argumentCount = 0
			  or: [(objectMemory isForwarded: rcvr) not])
				ifTrue: [newCopy := objectMemory clone: rcvr]
				ifFalse: [newCopy := 0].
			 newCopy = 0 ifTrue: "not enough memory most likely"
				[^self primitiveFail]].
	self pop: argumentCount + 1 thenPush: newCopy
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveClosureValue [
	| blockClosure numArgs closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(objectMemory isContext: outerContext) ifFalse:
		[^self primitiveFail].

	closureMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self activateNewClosure: blockClosure outer: outerContext method: closureMethod numArgs: numArgs mayContextSwitch: true
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveClosureValueNoContextSwitch [
	"An exact clone of primitiveClosureValue except that this version will not
	 check for interrupts on stack overflow.  It may invoke the garbage collector
	 but will not switch processes.  See checkForInterruptsMayContextSwitch:"
	<api>
	| blockClosure numArgs closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(objectMemory isContext: outerContext) ifFalse:
		[^self primitiveFail].

	closureMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self activateNewClosure: blockClosure outer: outerContext method: closureMethod numArgs: numArgs mayContextSwitch: false
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveClosureValueWithArgs [
	| argumentArray arraySize blockClosure numArgs closureMethod index outerContext |
	argumentArray := self stackTop.
	(objectMemory isArray: argumentArray) ifFalse:
		[^self primitiveFail].

	"Check for enough space in thisContext to push all args"
	arraySize := objectMemory numSlotsOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFail].

	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	arraySize = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(objectMemory isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self popStack.

	"Copy the arguments to the stack, and activate"
	index := 1.
	[index <= numArgs] whileTrue:
		[self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].

	self activateNewClosure: blockClosure outer: outerContext method: closureMethod numArgs: numArgs mayContextSwitch: true
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveCoarseLocalMicrosecondClock [
	"Return the value of the microsecond clock in the local timezone, as updated by the heartbeat, as an integer.
	 This is the number of microseconds since the Smalltalk epoch, 1901/1/1 12:00am.
	 The microsecond clock is at least 60 bits wide which means it'll get to around August
	 38435 before it wraps around.  Be sure to put it on your calendar.  The coarse clock is
	 updated by the heartbeat thread and as such is much cheaper than
	 primitiveUTCMicrosecondClock, which always entails a system call."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioLocalMicroseconds)
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveCoarseUTCMicrosecondClock [
	"Return the value of the microsecond clock as updated by the heartbeat as an integer.
	 This is the number of microseconds since the Smalltalk epoch, 1901/1/1 12:00am.
	 The microsecond clock is at least 60 bits wide which means it'll get to around August
	 38435 before it wraps around.  Be sure to put it on your calendar.  The coarse clock is
	 updated by the heartbeat thread and as such is much cheaper than
	 primitiveUTCMicrosecondClock, which always entails a system call."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioUTCMicroseconds)
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveCompareBytes [
	"Primitive. Compare two byte-indexed objects for equality"
	| arg1 arg2 len1 len2 |
	<export: true>
	argumentCount = 1 ifFalse:[self primitiveFail. ^self].
	arg1 := self stackValue: 1.
	arg2 := self stackValue: 0.
	((objectMemory isBytes: arg1) and:[objectMemory isBytes: arg2]) 
		ifFalse:[self primitiveFail. ^self].
	"Quick identity test"
	(arg1 = arg2) ifTrue:[^self pop: 2 thenPush: objectMemory trueObject].
	len1 := objectMemory byteSizeOf: arg1.
	len2 := objectMemory byteSizeOf: arg2.
	len1 = len2 ifFalse:[^self pop: 2 thenPush: objectMemory falseObject].
	0 to: len1-1 do:[:i|
		(objectMemory fetchByte: i ofObject: arg1) = (objectMemory fetchByte: i ofObject: arg2) 
			ifFalse:[^self pop: 2 thenPush: objectMemory falseObject]].
	self pop: 2 thenPush: objectMemory trueObject.

]

{ #category : #'string primitives' }
InterpreterPrimitives >> primitiveCompareWith [
	"<string1> primitiveCompareWith: string2 [collated: order] "
	<export: true>
	
	| string1 string2 order strLength1 strLength2 result |

	"1 - fetch the parameters from the stack"	
	argumentCount = 1 ifFalse:
		[argumentCount ~= 2 ifTrue:
			[^self primitiveFailFor: PrimErrBadNumArgs].
			 order := self stackTop.
			 ((objectMemory isBytes: order)
			 and: [(objectMemory numBytesOfBytes: order) = 256]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument]].
	string1 := self stackValue: argumentCount.
	string2 := self stackValue: argumentCount - 1. 
			
	"2 - check their types - all parameters are ByteObject"
	((objectMemory isBytes: string1)
	 and: [objectMemory isBytes: string2]) ifFalse: 
		[^self primitiveFailFor: PrimErrBadArgument].
	
	"3 - compare the strings"	
	strLength1 := objectMemory numBytesOfBytes: string1.
	strLength2 := objectMemory numBytesOfBytes: string2.
	result := order 
		ifNil: [self rawCompare: string1 length: strLength1 with: string2 length: strLength2 accessBlock:
				[:str :index | objectMemory fetchByte: index ofObject: str ]]
		ifNotNil: 
			[self rawCompare: string1 length: strLength1 with: string2 length: strLength2 accessBlock:
				[:str :index | objectMemory fetchByte: (objectMemory fetchByte: index ofObject: str) + 1 ofObject: order ]].

	self methodReturnInteger: result

	
	
	
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveConstantFill [
	"Fill the receiver, which must be an indexable non-pointer
	 object, with the given integer value."
	objectMemory hasSpurMemoryManagerAPI
		ifTrue: [self primitiveConstantFillSpur]
		ifFalse: [self primitiveConstantFillV3]
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveConstantFillSpur [
	"Fill the receiver, which must be an indexable non-pointer object, with the given integer value."
	<inline: true>
	| fillValue rcvr format end i oddBytes |
	<var: #fillValue type: #usqLong>
	<var: #end type: #usqInt>
	<var: #i type: #usqInt>
	fillValue := self positive64BitValueOf: self stackTop.
	rcvr := self stackValue: 1.
	(self successful
	 and: [(objectMemory isNonImmediate: rcvr)
	 and: [(format := objectMemory formatOf: rcvr) >= objectMemory sixtyFourBitIndexableFormat]]) ifFalse:
		[^self primitiveFail].
	format >= objectMemory firstShortFormat
		ifTrue:
			[format >= objectMemory firstByteFormat
				ifTrue:
					[(fillValue > 16rFF or: [format >= objectMemory firstCompiledMethodFormat]) ifTrue:
						[^self primitiveFail].
					 fillValue := fillValue + (fillValue << 8) + (fillValue << 16) + (fillValue << 24).
					 oddBytes := format bitAnd: 7]
				ifFalse:
					[fillValue > 16rFFFF ifTrue:
						[^self primitiveFail].
					 fillValue := fillValue + (fillValue << 16).
					 oddBytes := (format bitAnd: 3) << 1].
			 fillValue := fillValue + (fillValue << 32)]
		ifFalse:
			[format = objectMemory sixtyFourBitIndexableFormat
				ifTrue:
					[oddBytes := 0]
				ifFalse:
					[fillValue > 16rFFFFFFFF ifTrue:
						[^self primitiveFail].
					 fillValue := fillValue + (fillValue << 32).
					 oddBytes := (format bitAnd: 1) << 2]].
	end := objectMemory addressAfter: rcvr.
	i := rcvr + objectMemory baseHeaderSize.
	[i < end] whileTrue:
		[objectMemory long64At: i put: fillValue.
		 i := i + 8].
	"now ensure trailing bytes are zero"
	oddBytes > 0 ifTrue:
		[self flag: #endianness.
		 fillValue := fillValue >> (8 * oddBytes).
		 objectMemory long64At: i - 8 put: fillValue].
	self pop: 1
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveConstantFillV3 [
	"Fill the receiver, which must be an indexable bytes or words 
	 object, with the given integer value."
	<inline: true>
	| fillValue rcvr end i |
	<var: #end type: #usqInt>
	<var: #i type: #usqInt>
	fillValue := self positive32BitValueOf: self stackTop.
	rcvr := self stackValue: 1.
	self success: (objectMemory isWordsOrBytes: rcvr).
	(objectMemory isBytes: rcvr) ifTrue:
		[self success: (fillValue >= 0 and: [fillValue <= 255]).
		 fillValue := fillValue + (fillValue << 8) + (fillValue << 16) + (fillValue << 24)].
	self successful ifTrue:
		[end := rcvr + (objectMemory sizeBitsOf: rcvr).
		 i := rcvr + objectMemory baseHeaderSize.
		 [i < end] whileTrue:
			[objectMemory long32At: i put: fillValue.
			 i := i + 4].
		 self pop: 1]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveControlVMProfiling [
	"Primitive. Start or stop the VM profiler.  The first argument is a boolean
	 to switch profiling on or off.  The second argument is an integer or nil.
	 If an integer it determines the maximum number of samples in the VM's
	 sample buffer. Answer the current number of samples in the buffer."
	| onOffBar bufferSize numSamples |
	argumentCount ~= 2 ifTrue:
		[^self primitiveFail].
	(onOffBar := self stackValue: 1) = objectMemory trueObject
		ifTrue: [onOffBar := 1]
		ifFalse:
			[onOffBar = objectMemory falseObject
				ifTrue: [onOffBar := 0]
				ifFalse: [^self primitiveFail]].
	(bufferSize := self stackTop) = objectMemory nilObject
		ifTrue: [bufferSize := 0]
		ifFalse:
			[((objectMemory isIntegerObject: bufferSize)
			  and: [(bufferSize := objectMemory integerValueOf: bufferSize) > 0]) ifFalse:
				[^self primitiveFail]].
	numSamples := self cCode: 'ioControlNewProfile(onOffBar,bufferSize)' inSmalltalk: [1667].
	self pop: 3 thenPushInteger: numSamples
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveCopyObject [
	"Primitive. Copy the state of the receiver from the argument. 
		Fail if receiver and argument are of a different class.
		Fail if the receiver or argument are contexts (because of context-to-stack mapping).
		Fail if receiver and argument have different lengths (for indexable objects).
		Fail if the objects are not in a fit state to be copied (e.g. married contexts and Cogged methods)"
	| rcvr arg length |
	self methodArgumentCount >= 1 ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	arg := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isImmediate: arg) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].

	(objectMemory fetchClassTagOfNonImm: rcvr)
		~= (objectMemory fetchClassTagOfNonImm: arg) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].

	(objectMemory isWordsOrBytesNonImm: rcvr)
		ifTrue:
			[length := objectMemory numBytesOf: rcvr.
			((objectMemory formatOf: rcvr) = (objectMemory formatOf: arg)
			  and: [length = (objectMemory numBytesOf: arg)]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument].
			 self memcpy: (rcvr + objectMemory baseHeaderSize) asVoidPointer
				_: (arg + objectMemory baseHeaderSize) asVoidPointer
				_: length]
		ifFalse:
			[(self isAppropriateForCopyObject: rcvr) ifFalse:
				[^self primitiveFailFor: PrimErrBadReceiver].
			 length := objectMemory numSlotsOf: rcvr.
			 ((self isAppropriateForCopyObject: arg)
			  and: [length = (objectMemory lengthOf: arg)]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument].
			 0 to: length - 1 do:
				[:i|
				objectMemory
					storePointer: i
					ofObject: rcvr
					withValue: (objectMemory fetchPointer: i ofObject: arg)]].

	"Note: The above could be faster for young receivers but I don't think it'll matter"
	self pop: self methodArgumentCount "pop arg; answer receiver"
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveCrashVM [
	"Crash the VM by indirecting through a null pointer.  If the sole argument
	 is true crash in this thread, and if it is false crash in a new thread.  If the
	 argument is an integer use the method that implies.
		bit 0 = thread to crash in; 1 => this thread
		bit 1 = crash method; 0 => indirect through null pointer; 1 => call exit"

	| crashInThisThread |
	<export: true>
	(objectMemory isIntegerObject: self stackTop)
		ifTrue: [crashInThisThread := objectMemory integerValueOf: self stackTop]
		ifFalse: [crashInThisThread := self booleanValueOf: self stackTop].
	(self failed
	 or: [argumentCount ~= 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	self crashInThisOrAnotherThread: crashInThisThread.
	self pop: 1
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveDisablePowerManager [
	"Pass in a non-negative value to disable the architectures powermanager if any, zero to enable. This is a named (not numbered) primitive in the null module (ie the VM)"

	| integer |
	<export: true>
	integer := self stackIntegerValue: 0.
	self successful ifTrue: [
		self ioDisablePowerManager: integer.
		self pop: 1].  "integer; leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveDiv [
	| quotient |
	quotient := self doPrimitiveDiv: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: quotient
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveDivLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| result oopResult a aIsNegative b bIsNegative oopArg oopRcvr rem |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>
	<var: 'rem' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	b = 0 ifTrue:[self primitiveFail].
	self successful ifFalse:[^nil].

	result := a // b.
	
	a = 0
		ifFalse: [bIsNegative = aIsNegative
			ifFalse:
				["Round toward negative infinity"
				rem := a \\ b.
				rem = 0 ifFalse:
					["This can not overflow, because b > 1, otherwise rem = 0"
					result := result + 1]]].

	oopResult := self magnitude64BitIntegerFor: result neg: bIsNegative ~= aIsNegative.
	self successful ifTrue: [self pop: 2 thenPush: oopResult].
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveDivide [
	| integerReceiver integerArgument |
	integerReceiver := self stackIntegerValue: 1.
	integerArgument := self stackIntegerValue: 0.
	(integerArgument ~= 0 and: [integerReceiver \\ integerArgument = 0])
		ifTrue: [self pop2AndPushIntegerIfOK: integerReceiver // integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveDivideLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| a b result oopResult aIsNegative bIsNegative oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	self successful ifFalse:[^nil].
	
	"check for exact division"
	(b ~= 0 and:[a \\ b = 0]) ifFalse:[self primitiveFail. ^nil].

	result := a // b.
	oopResult := self magnitude64BitIntegerFor: result neg: aIsNegative ~= bIsNegative.

	self successful ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveEnterCriticalSection [
	"Attempt to enter a CriticalSection/Mutex.  If not owned, set the owner to the current
	 process and answer false. If owned by the current process  answer true.   Otherwise
	 suspend the process.  Answer if the receiver is owned by the current process.
	 For simulation if there is an argument it is taken to be the effective activeProcess
	 (see Process>>effectiveProcess)."
	| criticalSection owningProcessIndex owningProcess activeProc |
	argumentCount > 0
		ifTrue:
			[criticalSection := self stackValue: 1.  "rcvr"
			 activeProc := self stackTop]
		ifFalse:
			[criticalSection := self stackTop.  "rcvr"
			 activeProc := self activeProcess].
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := objectMemory fetchPointer: owningProcessIndex ofObject: criticalSection.
	owningProcess = objectMemory nilObject ifTrue:
		[objectMemory storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: argumentCount + 1 thenPush: objectMemory falseObject].
	owningProcess = activeProc ifTrue:
		[^self pop: argumentCount + 1 thenPush: objectMemory trueObject].
	"Arrange to answer false (unowned) when the process is resumed."
	self pop: argumentCount + 1 thenPush: objectMemory falseObject.
	self addLastLink: activeProc toList: criticalSection.
	self transferTo: self wakeHighestPriority
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveEqual [
	| integerReceiver integerArgument result |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	(objectMemory areIntegers: integerReceiver and: integerArgument)
		ifTrue: [self pop: 2 thenPushBool: integerReceiver = integerArgument]
		ifFalse:
			[result := objectMemory hasSixtyFourBitImmediates
						ifTrue:
							[(self signed64BitValueOf: integerReceiver)
								= (self signed64BitValueOf: integerArgument)]
						ifFalse:
							[(self positiveMachineIntegerValueOf: integerReceiver)
								= (self positiveMachineIntegerValueOf: integerArgument)].
			 self successful ifTrue:
				[self pop: 2 thenPushBool: result]]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr = integerArg]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveExitCriticalSection [
	"Exit the critical section.
	 This may change the active process as a result."
	| criticalSection owningProcessIndex owningProcess |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	(self isEmptyList: criticalSection)
		ifTrue:
			[objectMemory storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: objectMemory nilObject]
		ifFalse:
			[owningProcess := self removeFirstLinkOfList: criticalSection.
			 "store check unnecessary because criticalSection referred to owningProcess
			  via its FirstLinkIndex slot before owningProcess was removed."
			 objectMemory storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: owningProcess.
			 "Note that resume: isn't fair; it won't suspend the active process.
			  For fairness we must do the equivalent of a primitiveYield, but that
			  may break old code, so we stick with unfair resume:."
			self resume: owningProcess preemptedYieldingIf: preemptionYields]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveExitToDebugger [

	self error: 'Exit to debugger at user request'.
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveExp [
	"Computes E raised to the receiver power.
	 N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		[self stackTopPut: (objectMemory floatObjectOf:
								(self cCode: [rcvr exp]
									inSmalltalk: [rcvr = rcvr
													ifTrue: [rcvr exp]
													ifFalse: [Float nan]]))]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveExponent [
	"Exponent part of this float.
	 N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr pwr |
	<var: #rcvr type: #double>
	<var: #pwr type: #int>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		["rcvr = frac * 2^pwr, where frac is in [0.5..1.0)"
		 self cCode: [self fr: rcvr exp: (self addressOf: pwr)]
			inSmalltalk: [pwr := rcvr exponent].
		 self stackTopPut: (objectMemory integerObjectOf: pwr - 1)]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> primitiveFail [
	"Set general (unspecified) primitive failure.  Don't overwrite an error code that has already been set."

	"Use returnTypeC: #sqInt because that's the way it is defined in sq.h.
	 Use no explicit return so that Slang doesn't fail an inlining type-check when
	 a primitive with return type void uses ^self primitiveFail to exit."
	<api>
	<returnTypeC: #sqInt>
	<inline: true>
	self successful ifTrue:
		[primFailCode := 1]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> primitiveFailFor: reasonCode [
	"Set specific primitive failure.
	 N.B. primitiveFailFor: PrimNoErr is expected to clear the primFailCode."
	<api>
	^primFailCode := reasonCode
]

{ #category : #'primitive support' }
InterpreterPrimitives >> primitiveFailForFFIException: exceptionCode at: pc [
	<var: 'exceptionCode' type: #usqLong>
	<var: 'pc' type: #usqInt>
	"Set PrimErrFFIException primitive failure and associated exceptionCode (a.k.a. 
	 osErrorCode) and exceptionPC. Under control of the ffiExceptionResponse flag,
	 if in a primitive with an error code and the inFFIFlags indicate we're in an FFI call,
	 then fail the primitive.
	 ffiExceptionResponse < 0 never fail
	 ffiExceptionResponse = 0 fail if method has a primitive error code (default)
	 ffiExceptionResponse > 0 always fail"
	<api>
	((inFFIFlags noMask: DisownVMForFFICall)	"i.e. not in an FFI call"
	 or: [ffiExceptionResponse < 0]) ifTrue:		"i.e. never fail"
		[^self].
	osErrorCode := self cCoerceSimple: exceptionCode to: #sqLong.
	exceptionPC := pc.
	primFailCode := PrimErrFFIException.
	(ffiExceptionResponse > 0					"always fail..."
	 or: [(objectMemory isOopCompiledMethod: newMethod)
		 and: [self methodUsesPrimitiveErrorCode: newMethod]]) ifTrue:
		[self ownVM: DisownVMForFFICall. "To take ownership but importantly to reset inFFIFlags"
		 self activateFailingPrimitiveMethod]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> primitiveFailForOSError: osError [
	<var: 'osError' type: #sqLong>
	"Set PrimErrOSError primitive failure and associated osErrorCode."
	<api>
	osErrorCode := osError.
	^primFailCode := PrimErrOSError
]

{ #category : #'primitive support' }
InterpreterPrimitives >> primitiveFailureCode [
	<api>
	^primFailCode
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveFetchNextMourner [
	<option: #SpurObjectMemory>
	objectMemory dequeueMourner
		ifNil: [self primitiveFailFor: PrimErrNotFound]
		ifNotNil: [:mourner| self pop: 1 thenPush: mourner]
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFindHandlerContext [
	"Primitive. Search up the context stack for the next method context marked
	 for exception handling starting at the receiver. Return nil if none found"
	self subclassResponsibility
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFindNextUnwindContext [
	"Primitive. Search up the context stack for the next method context marked for unwind
	 handling from the receiver up to but not including the argument. Return nil if none found."
	self subclassResponsibility
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatAdd [
	^ self primitiveFloatAdd: (self stackValue: 1) toArg: self stackTop
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveFloatAt [
	"Provide platform-independent access to 32-bit words comprising
	 a Float.  Map index 1 onto the most significant word and index 2
	 onto the least significant word."
	| rcvr index result indexToUse |
	<var: #result type: #usqInt>
	
	rcvr := self stackValue: 1.
	index := self stackTop.
	
	index = ConstOne 
		ifTrue: [ indexToUse := 0 ]
		ifFalse: [
			index = ConstTwo 
				ifTrue: [ indexToUse := 1 ]
				ifFalse: [ 
					^ self primitiveFailFor: ((objectMemory isIntegerObject: index)
							ifTrue: [PrimErrBadIndex]
							ifFalse: [PrimErrBadArgument]) ]].
	
	VMBIGENDIAN ifFalse: [ 
		indexToUse := indexToUse = 0 ifTrue: [ 1 ] ifFalse: [ 0 ]].
	
	result := self positive32BitIntegerFor: (objectMemory
							fetchLong32: indexToUse
							ofFloatObject: rcvr).
	
	^self pop: 2 thenPush: result.

]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveFloatAtPut [
	"Provide platform-independent access to 32-bit words comprising
	 a Float.  Map index 1 onto the most significant word and index 2
	 onto the least significant word."
	| rcvr index oopToStore valueToStore |
	<var: #valueToStore type: #usqInt>
	oopToStore := self stackTop.
	valueToStore := self positive32BitValueOf: oopToStore.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	index := self stackValue: 1.
	(objectMemory isImmediateFloat: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	index = ConstOne ifTrue:
		[objectMemory storeLong32: (VMBIGENDIAN ifTrue: [0] ifFalse: [1])
			ofObject: rcvr
			withValue: valueToStore.
		^self pop: 3 thenPush: oopToStore].
	index = ConstTwo ifTrue:
		[objectMemory storeLong32: (VMBIGENDIAN ifTrue: [1] ifFalse: [0])
			ofObject: rcvr
			withValue: valueToStore.
		^self pop: 3 thenPush: oopToStore].
	self primitiveFailFor: ((objectMemory isIntegerObject: index)
							ifTrue: [PrimErrBadIndex]
							ifFalse: [PrimErrBadArgument])
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatDivide [
	self primitiveFloatDivide: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatGreaterOrEqual [
	| aBool |
	aBool := self primitiveFloatGreaterOrEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatGreaterThan [
	| aBool |
	aBool := self primitiveFloatGreater: (self stackValue: 1) thanArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatLessOrEqual [
	| aBool |
	aBool := self primitiveFloatLessOrEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatLessThan [
	| aBool |
	aBool := self primitiveFloatLess: (self stackValue: 1) thanArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatMultiply [
	self primitiveFloatMultiply: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatNotEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool not]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFloatSubtract [
	^ self primitiveFloatSubtract: (self stackValue: 1) fromArg: self stackTop
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveFlushCache [
	"Clear the method lookup cache. This must be done after every programming change."

	self flushMethodCache
]

{ #category : #'plugin primitives' }
InterpreterPrimitives >> primitiveFlushExternalPrimitives [
	"Primitive. Flush all the existing external primitives in the image thus forcing a reload on next invokation."
	self flushExternalPrimitives
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveForceDisplayUpdate [
	"On some platforms, this primitive forces enqueued display updates to be processed immediately. On others, it does nothing."

	self ioForceDisplayUpdate.

]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveForceTenure [
	"Set force tenure flag to true, this forces a tenure operation on the next incremental GC"

	<export: true>
	<option: #SqueakV3ObjectMemory>
	objectMemory forceTenureFlag: 1
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveFormPrint [
	"On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer."

	| landscapeFlag vScale hScale rcvr bitsArray w h
	 depth pixelsPerWord wordsPerLine bitsArraySize ok |

	<var: #vScale type: #double>
	<var: #hScale type: #double>
	landscapeFlag := self booleanValueOf: self stackTop.
	vScale := objectMemory floatValueOf: (self stackValue: 1).
	hScale := objectMemory floatValueOf: (self stackValue: 2).
	rcvr := self stackValue: 3.
	((objectMemory isPointers: rcvr)
	 and: [(objectMemory lengthOf: rcvr) >= 4]) ifFalse:
		[self success: false].
	self successful ifTrue:
		[bitsArray := objectMemory fetchPointer: 0 ofObject: rcvr.
		w := self fetchInteger: 1 ofObject: rcvr.
		h := self fetchInteger: 2 ofObject: rcvr.
		depth := self fetchInteger: 3 ofObject: rcvr.
		(w > 0 and: [h > 0]) ifFalse: [self success: false].
		pixelsPerWord := 32 // depth.
		wordsPerLine := (w + (pixelsPerWord - 1)) // pixelsPerWord.
		(objectMemory isWordsOrBytes: bitsArray)
			ifTrue:
				[bitsArraySize := objectMemory numBytesOf: bitsArray.
				self success: (bitsArraySize = (wordsPerLine * h * 4))]
			ifFalse: [self success: false]].	
	self successful ifTrue:
		[ok := self cCode: 'ioFormPrint(bitsArray + BaseHeaderSize, w, h, depth, hScale, vScale, landscapeFlag)'.
		self success: ok].
	self successful ifTrue:
		[self pop: 3]	"pop hScale, vScale, and landscapeFlag; leave rcvr on stack"
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFractionalPart [
	"Fractional part of this float.
	 N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr trunc |
	<var: #rcvr type: #double>
	<var: #trunc type: #double>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		[self stackTopPut: (objectMemory floatObjectOf:
							(self cCode: [self mod: rcvr f: (self addressOf: trunc)]
								inSmalltalk: [rcvr fractionPart]))]
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFullClosureValue [
	<option: #SistaV1BytecodeSet>
	| blockClosure numArgs closureMethod |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	closureMethod := objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: blockClosure.
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self activateNewFullClosure: blockClosure method: closureMethod numArgs: numArgs mayContextSwitch: true
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFullClosureValueNoContextSwitch [
	"An exact clone of primitiveFullClosureValue except that this version will not
	 check for interrupts on stack overflow.  It may invoke the garbage collector
	 but will not switch processes.  See checkForInterruptsMayContextSwitch:"
	<api>
	<option: #SistaV1BytecodeSet>
	| blockClosure numArgs closureMethod |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	closureMethod := objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: blockClosure.
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self activateNewFullClosure: blockClosure method: closureMethod numArgs: numArgs mayContextSwitch: false
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFullClosureValueWithArgs [
	<option: #SistaV1BytecodeSet>
	| argumentArray arraySize blockClosure numArgs closureMethod index |
	argumentArray := self stackTop.
	(objectMemory isArray: argumentArray) ifFalse:
		[^self primitiveFail].

	"Check for enough space in thisContext to push all args"
	arraySize := objectMemory numSlotsOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFail].

	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	arraySize = numArgs ifFalse:
		[^self primitiveFail].

	closureMethod := objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: blockClosure.
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self popStack.

	"Copy the arguments to the stack, and activate"
	index := 1.
	[index <= numArgs] whileTrue:
		[self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].

	self activateNewFullClosure: blockClosure method: closureMethod numArgs: numArgs mayContextSwitch: true
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveFullGC [
	"Do a full garbage collection.  In SqueakV3ObjectMemory, answer the number
	 of bytes available (including swap space if dynamic memory management is
	 supported).  In Spur, answer the size of the largest free chunk."

	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[self pop: 1 thenPushInteger: objectMemory fullGC.
		 ^self].
	objectMemory fullGCLock > 0 ifTrue:
		[self primitiveFailFor: PrimErrInappropriate.
		 ^self].
	objectMemory incrementalGC.  "maximimize space for forwarding table"
	objectMemory fullGC.
	self pop: 1 thenPushInteger: (objectMemory bytesLeft: true)
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The 
	result is a string, which will be empty if the attribute is not 
	defined."
	| attr sz s |
	attr := self stackIntegerValue: 0.
	self successful
		ifTrue: [sz := self attributeSize: attr].
	self successful
		ifTrue: [s := objectMemory
						instantiateClass: (objectMemory splObj: ClassByteString)
						indexableSize: sz.
			self
				getAttribute: attr
				Into: s + objectMemory baseHeaderSize
				Length: sz.
			self pop: 2 thenPush: s]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveGetImmutability [
	<option: #IMMUTABILITY>
	| rcvr |
	rcvr := self stackValue: 0.
	self pop: argumentCount + 1 thenPushBool: (objectMemory isOopImmutable: rcvr)
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveGetLogDirectory [
	"Primitive. Answer the VM's current log directory"
	| ptr sz stringOop |
	<var: 'ptr' type: 'char*'>
	<export: true>
	ptr := self ioGetLogDirectory.
	ptr == nil ifTrue:[^self success: false].
	sz := self strlen: ptr.
	stringOop := objectMemory instantiateClass: objectMemory classString indexableSize: sz.
	0 to: sz-1 do:[:i| objectMemory storeByte: i ofObject: stringOop withValue: (ptr at: i)].
	self pop: argumentCount+1 thenPush: stringOop
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveGetNextEvent [
	"Primitive. Return the next input event from the VM event queue."
	| evtBuf arg value eventTypeIs |
	<var: #evtBuf declareC:'sqIntptr_t evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 }'>
	self cCode: [] inSmalltalk: [evtBuf := objectMemory newInputEventAccessorOfSize: 8].
	arg := self stackTop.
	((objectMemory isArray: arg) and:[(objectMemory slotSizeOf: arg) = 8]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	self ioGetNextEvent: (self cCoerce: evtBuf to: 'sqInputEvent*').
	self successful ifFalse:
		[^nil].

	"Event type"
	eventTypeIs := evtBuf at: 0.
	self storeInteger: 0 ofObject: arg withValue: (evtBuf at: 0).
	self successful ifFalse:
		[^nil].

	eventTypeIs = 6 
		ifTrue: "Event is Complex, assume evtBuf is populated correctly and return"
			[1 to: 7 do: [:i |
				value := evtBuf at: i.
				self storePointer: i ofObject: arg withValue: value]]
		ifFalse:
			["Event time stamp"
			self storeInteger: 1 ofObject: arg withValue: ((evtBuf at: 1) bitAnd: MillisecondClockMask).
			self successful ifFalse:
				[^nil].	

			"Event arguments"
			2 to: 7 do:[:i|
				value := evtBuf at: i.
				(objectMemory isIntegerValue: value)
					ifTrue:[self storeInteger: i ofObject: arg withValue: value]
					ifFalse:
						[value := self positiveMachineIntegerFor: value.
						objectMemory storePointer: i ofObject: arg withValue: value]]].

	self successful ifTrue: [self pop: 1]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveGetWindowLabel [
	"Primitive. Answer the OS window's label"
	| ptr sz labelOop |
	<var: 'ptr' type: 'char*'>
	<export: true>
	ptr := self ioGetWindowLabel.
	ptr == nil ifTrue:[^self success: false].
	sz := self strlen: ptr.
	labelOop := objectMemory instantiateClass: objectMemory classString indexableSize: sz.
	0 to: sz-1 do:[:i| objectMemory storeByte: i ofObject: labelOop withValue: (ptr at: i)].
	self pop: argumentCount+1 thenPush: labelOop
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveGetWindowSize [
	"Primitive. Answer the OS window's size (extent)"
	| w h |
	<export: true>
	w := self ioGetWindowWidth.
	h := self ioGetWindowHeight.
	self pop: self methodArgumentCount+1.
	self push: (self makePointwithxValue: w yValue: h).
]

{ #category : #'other primitives' }
InterpreterPrimitives >> primitiveGetenv [
	"Access to environment variables via getenv.  No putenv or setenv as yet."
	| key var result |
	<export: true>
	<var: #key type: #'char *'>
	<var: #var type: #'char *'>
	sHEAFn ~= 0 ifTrue: "secHasEnvironmentAccess"
		[self sHEAFn ifFalse: [^self primitiveFailFor: PrimErrInappropriate]].
	key := self cStringOrNullFor: self stackTop.
	key = 0 ifTrue:
		[self successful ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 ^self primitiveFailFor: primFailCode].
	var := self getenv: key.
	self free: key.
	var ~= 0 ifTrue:
		[result := objectMemory stringForCString: var.
		 result ifNil:
			[^self primitiveFailFor: PrimErrNoMemory]].
	self assert: primFailCode = 0.
	self pop: 2 thenPush: (var = 0 ifTrue: [objectMemory nilObject] ifFalse: [result])
]

{ #category : #'simulation support' }
InterpreterPrimitives >> primitiveGetenv: aByteStringOrByteArray [
	<doNotGenerate>
	<primitive: 'primitiveGetenv' module: '' error: ec>
	ec == #'bad argument' ifTrue:
		[aByteStringOrByteArray isString ifFalse:
			[^self getenv: aByteStringOrByteArray asString]].
	self primitiveFail
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveGreaterOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	(objectMemory areIntegers: integerReceiver and: integerArgument)
		ifTrue: [self cCode: '' inSmalltalk:
					[integerReceiver := objectMemory integerValueOf: integerReceiver.
					 integerArgument := objectMemory integerValueOf: integerArgument].
				self pop: 2 thenPushBool: integerReceiver >= integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveGreaterOrEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr >= integerArg]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveGreaterThan [
	| integerReceiver integerArgument |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	(objectMemory areIntegers: integerReceiver and: integerArgument)
		ifTrue: [self cCode: '' inSmalltalk:
					[integerReceiver := objectMemory integerValueOf: integerReceiver.
					 integerArgument := objectMemory integerValueOf: integerArgument].
				self pop: 2 thenPushBool: integerReceiver > integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveGreaterThanLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr > integerArg]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveGrowMemoryByAtLeast [
	<option: #SpurObjectMemory>
	| ammount |
	ammount := self stackTop.
	(objectMemory isIntegerObject: ammount) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory growOldSpaceByAtLeast: (objectMemory integerValueOf: ammount))
		ifNil: [self primitiveFailFor: PrimErrNoMemory]
		ifNotNil: [:segSize| self pop: 2 thenPushInteger: segSize]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveHashMultiply [
	"Implement 28-bit hashMultiply for SmallInteger and LargePositiveInteger receivers."
	| value |
	value := self stackTop.
	(objectMemory isIntegerObject: value)
		ifTrue: [value := objectMemory integerValueOf: value]
		ifFalse:
			[| ok |
			 ok := objectMemory is: value instanceOf: (objectMemory splObj: ClassLargePositiveInteger) compactClassIndex: ClassLargePositiveIntegerCompactIndex.
			 ok ifFalse:
				[^self primitiveFailFor: PrimErrBadReceiver].
			 value := objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: value)].
	self pop: 1
		thenPush: (objectMemory integerObjectOf: (value * HashMultiplyConstant bitAnd: 16rFFFFFFF))
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveHeartbeatFrequency [
	"Answer the heartbeat frequency in beats per second.  If the argument is true, reset the frequency measure."
	<export: true>
	| reset |
	reset := argumentCount = 1 and: [self stackTop = objectMemory trueObject].
	self pop: argumentCount + 1
		thenPush: (self positive32BitIntegerFor: (self ioHeartbeatFrequency: reset))
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveHighResClock [
	"Return the value of the high resolution clock if this system has any. The exact frequency of the high res clock is undefined specifically so that we can use processor dependent instructions (like RDTSC). The only use for the high res clock is for profiling where we can allocate time based on sub-msec resolution of the high res clock. If no high-resolution counter is available, the platform should return zero."
	<export: true>
	self pop: 1.
	self push: (self positive64BitIntegerFor: self ioHighResClock).
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveIdentical [
	"is the receiver/first argument the same object as the (last) argument?.
	 pop argumentCount because this can be used as a mirror primitive."
	| thisObject otherObject |
	otherObject := self stackValue: 1.
	thisObject := self stackTop.
	((objectMemory isOopForwarded: otherObject)
	 or: [argumentCount > 1
		 and: [objectMemory isOopForwarded: thisObject]])
		ifTrue:
			[self primitiveFailFor: PrimErrBadArgument]
		ifFalse:
			[self pop: argumentCount + 1 thenPushBool: thisObject = otherObject]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveIdentityHash [
	| thisReceiver |
	thisReceiver := self stackTop.
	((objectMemory isImmediate: thisReceiver)
	 or: [argumentCount > 0
		 and: [objectMemory isForwarded: thisReceiver]])
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount + 1
					thenPushInteger: (objectMemory hashBitsOf: thisReceiver)]
]

{ #category : #'other primitives' }
InterpreterPrimitives >> primitiveImageFormatVersion [
	"Answer an integer identifying the type of image. The image version number may
	identify the format of the image (e.g. 32 or 64-bit word size) or specific requirements
	of the image (e.g. block closure support required).
	
	This is a named (not numbered) primitive in the null module (ie the VM)"

	<export: true>
	self pop: 1 thenPush: (self positive32BitIntegerFor: self imageFormatVersion)

]

{ #category : #'other primitives' }
InterpreterPrimitives >> primitiveImageName [
	"When called with a single string argument, record the string as the current image file name. When called with zero arguments, return a string containing the current image file name."

	| s sz sCRIfn okToRename |
	<var: #sCRIfn type: 'void *'>
	argumentCount = 1 ifTrue: [
		"If the security plugin can be loaded, use it to check for rename permission.
		If not, assume it's ok"
		sCRIfn := self ioLoadFunction: 'secCanRenameImage' From: 'SecurityPlugin'.
		sCRIfn ~= 0 ifTrue:
			[okToRename := self cCode: '((sqInt (*)(void))sCRIfn)()'
								inSmalltalk: [self dispatchMappedPluginEntry: sCRIfn].
			okToRename ifFalse:
				[^self primitiveFail]].
		s := self stackTop.
		self assertClassOf: s is: (objectMemory splObj: ClassByteString).
		self successful ifTrue: [
			sz := self stSizeOf: s.
			self imageNamePut: (s + objectMemory baseHeaderSize) Length: sz.
			self pop: 1.  "pop s, leave rcvr on stack"
		].
	] ifFalse: [
		sz := self imageNameSize.
		s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: sz.
		self imageNameGet: (s + objectMemory baseHeaderSize) Length: sz.
		self pop: 1 thenPush: s
	]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveImmediateAsInteger [
	"For a Smalllnteger, answer itself.
	 For a Character, answer its code as an unsigned integer.
	 For a SmallFloat, answer the signed, but unadjusted bit pattern (so as to keep the result a SmallInteger).
	 This is a good value for an immediate's hash."
	<option: #SpurObjectMemory>
	| oop value |
	oop := self stackTop.
	(objectMemory isIntegerObject: oop) ifTrue:
		[value := objectMemory integerValueOf: oop] ifFalse:
	[(objectMemory isCharacterObject: oop) ifTrue:
		[value := objectMemory characterValueOf: oop] ifFalse:
	[(objectMemory isImmediateFloat: oop) ifTrue:
		[value := objectMemory rotatedFloatBitsOf: oop] ifFalse:
	[^self primitiveFailFor: PrimErrBadReceiver]]].
	self pop: argumentCount + 1 thenPushInteger: value
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available.
	 (Note: more space may be made available by doing a full garbage collection."

	objectMemory hasSpurMemoryManagerAPI
		ifTrue: [objectMemory scavengingGC]
		ifFalse: [objectMemory incrementalGC].
	self pop: 1 thenPushInteger: (objectMemory bytesLeft: false)
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveInputSemaphore [
	"Register the input semaphore. If the argument is not a 
	Semaphore, unregister the current input semaphore."
	| arg |
	arg := self stackTop.
	(objectMemory isIntegerObject: arg) ifTrue:
		["If arg is integer, then use it as an index 
		  into the external objects array and install it 
		  as the new event semaphore"
		 self ioSetInputSemaphore: (objectMemory integerValueOf: arg).
		 self successful ifTrue:
			[self pop: 1].
		 ^nil].

	"old code for compatibility"
	TheInputSemaphore = nil ifTrue:
		[^self primitiveFail].
	(arg = objectMemory nilObject
	 or: [objectMemory isSemaphoreOop: arg])
		ifTrue:
			[objectMemory splObj: TheInputSemaphore put: arg.
			 self pop: 1]
		ifFalse:
			[self primitiveFailFor: PrimErrBadArgument]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveInputWord [
	"Return an integer indicating the reason for the most recent input interrupt."

	self pop: 1 thenPushInteger: 0.	"noop for now"
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1 "e.g. object:instVarAt:"
		and: [objectMemory isOopForwarded: rcvr]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	hdr := self baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	value := self subscript: rcvr with: index format: fmt.
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 2 "e.g. object:instVarAt:put:"
		and: [objectMemory isOopForwarded: rcvr]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	index := objectMemory integerValueOf: index.
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	self subscript: rcvr with: index storing: newValue format: fmt.
	self pop: argumentCount + 1 thenPush: newValue
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveIntegerAt [
	SPURVM
		ifTrue: [self primitiveSpurIntegerAt] "Answer the signed integer element of a pure bits receiver"
		ifFalse: [self primitiveV3IntegerAt]    "Answer the 32 bit signed integer contents of a words receiver"
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveIntegerAtPut [
	SPURVM
		ifTrue: [self primitiveSpurIntegerAtPut] "Assign an indexable variable of a pure bits receiver with a signed integer."
		ifFalse: [self primitiveV3IntegerAtPut]    "Assign an indexable variable of a words receiver with a 32 bit signed integer."
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveInterruptChecksPerMSec [
	"Primitive. Answer the number of interrupt checks per milliseconds that we execute
	on this machine. This can be used to adjust the sub-msecs profiler to check (roughly) 
	n times per millisecond."
	<export: true>
	self methodArgumentCount = 0 ifFalse:[^self success: false].
	self pop: 1 thenPush: (objectMemory integerObjectOf: self ioHeartbeatMilliseconds).
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveInterruptSemaphore [
	"Register the user interrupt semaphore. If the argument is 
	not a Semaphore, unregister the current interrupt 
	semaphore. "
	| arg |
	arg := self stackTop.
	(arg = objectMemory nilObject
	 or: [objectMemory isSemaphoreOop: arg])
		ifTrue:
			[objectMemory splObj: TheInterruptSemaphore put: arg.
			 self pop: 1]
		ifFalse:
			[self primitiveFailFor: PrimErrBadArgument]
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveInvokeObjectAsMethod [
	"Primitive. 'Invoke' an object like a function, sending the special message 
		run: originalSelector with: arguments in: aReceiver.
	"
	<returnTypeC: #void>
	| runReceiver runArgs lookupClassTag |
	runArgs := objectMemory hasSpurMemoryManagerAPI
					ifTrue: [objectMemory
								eeInstantiateClassIndex: ClassArrayCompactIndex
								format: objectMemory arrayFormat
								numSlots: argumentCount]
					ifFalse: [objectMemory
								eeInstantiateClass: (objectMemory splObj: ClassArray)
								indexableSize: argumentCount].
	argumentCount - 1 to: 0 by: -1  do:
		[:i| objectMemory storePointerUnchecked: i ofObject: runArgs withValue: self popStack].

	runReceiver := self popStack.
	"setup send of newMethod run: originalSelector with: runArgs in: runReceiver"
	self push: newMethod. "newReceiver"
	self push: messageSelector "original selector".
	self push: runArgs.
	self push: runReceiver.

	"stack is clean here"

	messageSelector := objectMemory splObj: SelectorRunWithIn.
	argumentCount := 3.
	lookupClassTag := objectMemory fetchClassTagOf: newMethod.
	self findNewMethodInClassTag: lookupClassTag.
	self executeNewMethod.  "Recursive xeq affects successFlag"
	self initPrimCall
]

{ #category : #'other primitives' }
InterpreterPrimitives >> primitiveIsBigEnder [
	"Answer if running on a big endian machine."
	<export: true>
	self pop: 1 thenPushBool: VMBIGENDIAN
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveIsPinned [
	"Answer if the receiver is pinned, i.e. immobile."
	<option: #SpurObjectMemory>
	| obj |
	obj := self stackTop.
	((objectMemory isImmediate: obj)
	 or: [objectMemory isForwarded: obj]) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	self pop: argumentCount + 1
		thenPushBool: (objectMemory isPinned: obj)
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveIsRoot [
	"Primitive. Answer whether the argument to the primitive is a root for young space"
	| oop |
	<export: true>
	<option: #SqueakV3ObjectMemory>
	oop := self stackObjectValue: 0.
	self successful ifTrue:
		[self
			pop: argumentCount + 1
			thenPushBool: (objectMemory isYoungRoot: oop)]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveIsWindowObscured [
	"Primitive. Answer whether the OS window is currently partially or fully obscured."
	<export: true>
	self pop: self methodArgumentCount+1.
	self pushBool: self ioIsWindowObscured.

]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveIsYoung [
	"Primitive. Answer whether the argument to the primitive resides in young space."
	| oop |
	<export: true>
	<option: #SqueakV3ObjectMemory> "for now..."
	oop := self stackObjectValue: 0.
	self successful ifTrue:
		[self pop: argumentCount + 1 thenPushBool: (self oop: oop isGreaterThanOrEqualTo: objectMemory youngStart)]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveKbdNext [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and remove it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| keystrokeWord |
	self pop: 1.
	keystrokeWord := self ioGetKeystroke.
	keystrokeWord >= 0
		ifTrue: [self pushInteger: keystrokeWord]
		ifFalse: [self push: objectMemory nilObject].
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveKbdPeek [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and without removing it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| keystrokeWord |
	self pop: 1.
	keystrokeWord := self ioPeekKeystroke.
	keystrokeWord >= 0
		ifTrue: [self pushInteger: keystrokeWord]
		ifFalse: [self push: objectMemory nilObject].
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveLessOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	(objectMemory areIntegers: integerReceiver and: integerArgument)
		ifTrue: [self cCode: '' inSmalltalk:
					[integerReceiver := objectMemory integerValueOf: integerReceiver.
					 integerArgument := objectMemory integerValueOf: integerArgument].
				self pop: 2 thenPushBool: integerReceiver <= integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveLessOrEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr <= integerArg]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveLessThan [
	| integerReceiver integerArgument |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	(objectMemory areIntegers: integerReceiver and: integerArgument)
		ifTrue: [self cCode: '' inSmalltalk:
					[integerReceiver := objectMemory integerValueOf: integerReceiver.
					 integerArgument := objectMemory integerValueOf: integerArgument].
				self pop: 2 thenPushBool: integerReceiver < integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveLessThanLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr < integerArg]
]

{ #category : #'plugin primitives' }
InterpreterPrimitives >> primitiveListBuiltinModule [
	"Primitive. Return the n-th builtin module name."
	| moduleName index length nameOop |
	<var: #moduleName type: #'char *'>
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	index := self stackIntegerValue: 0.
	index <= 0 ifTrue:[^self primitiveFail].
	moduleName := self ioListBuiltinModule: index.
	moduleName == nil ifTrue:[
		self pop: 2. "arg+rcvr"
		^self push: objectMemory nilObject].
	length := self strlen: moduleName.
	nameOop := objectMemory instantiateClass: objectMemory classString indexableSize: length.
	0 to: length-1 do:[:i|
		objectMemory storeByte: i ofObject: nameOop withValue: (moduleName at: i)].
	self forceInterruptCheck.
	self pop: 2 thenPush: nameOop
]

{ #category : #'plugin primitives' }
InterpreterPrimitives >> primitiveListExternalModule [
	"Primitive. Return the n-th loaded external module name."
	| moduleName index length nameOop |
	<var: #moduleName type: #'char *'>
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	index := self stackIntegerValue: 0.
	index <= 0 ifTrue:[^self primitiveFail].
	moduleName := self ioListLoadedModule: index.
	moduleName == nil ifTrue:[
		self pop: 2. "arg+rcvr"
		^self push: objectMemory nilObject].
	length := self strlen: moduleName.
	nameOop := objectMemory instantiateClass: objectMemory classString indexableSize: length.
	0 to: length-1 do:[:i|
		objectMemory storeByte: i ofObject: nameOop withValue: (moduleName at: i)].
	self forceInterruptCheck.
	self pop: 2 thenPush: nameOop
]

{ #category : #'image segment in/out' }
InterpreterPrimitives >> primitiveLoadImageSegment [
	"This primitive is called from Smalltalk as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray.

	 This primitive will load a binary image segment created by primitiveStoreImageSegment.
	 It expects the outPointer array to be of the proper size, and the wordArray to be well
	 formed.  It will return as its value the original array of roots, and the erstwhile
	 segmentWordArray will have been truncated to a size of one word, i.e. retaining the version
	 stamp.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to
	 an unrecognizable and unusable jumble.  But what more could you have done with it anyway?
	 [How about saving it so the system functions as primtiives are intended?  eem 5/9/2017 16:31]

	 In Spur, if the primitive succeeds, the segmentWordArray is also becomed into the array of loaded
	 objects, to allow fixing up of loaded objects directly without nextObject, which Spur doesn't support."

	| outPointerArray segmentWordArray result |

	outPointerArray := self stackTop.
	segmentWordArray := self stackValue: 1.

	"Essential type checks"
	((objectMemory isArray: outPointerArray)		"Must be indexable pointers"
	 and: [objectMemory isWords: segmentWordArray])	"Must be indexable words"
		ifFalse: [^self primitiveFail].

	"the engine returns the roots array which was first in the segment, or an error code on failure."
	result := objectMemory loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray.
	(self oop: result isGreaterThan: segmentWordArray)
		ifTrue: [self pop: 3 thenPush: result]
		ifFalse: [self primitiveFailFor: result]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveLocalMicrosecondClock [
	"Return the value of the microsecond clock in the local timezone as an integer.
	 This is the number of microseconds since the Smalltalk epoch, 1901/1/1 12:00am.
	 The microsecond clock is at least 60 bits wide which means it'll get to around August
	 38435 before it wraps around.  Be sure to put it on your calendar.  This primitive
	 accesses the time as answered by the OS."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioLocalMicrosecondsNow)
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveLogN [
	"Natural log.
	 N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		[self stackTopPut: (objectMemory floatObjectOf:
								(self cCode: [rcvr log]
									inSmalltalk: [rcvr = rcvr
													ifTrue: [rcvr ln]
													ifFalse: [Float nan]]))]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveLowSpaceSemaphore [
	"Register the low-space semaphore. If the argument is not a 
	 Semaphore, unregister the current low-space Semaphore."
	| arg |
	arg := self stackTop.
	(arg = objectMemory nilObject
	 or: [objectMemory isSemaphoreOop: arg])
		ifTrue:
			[objectMemory splObj: TheLowSpaceSemaphore put: arg.
			 self pop: 1]
		ifFalse:
			[self primitiveFailFor: PrimErrBadArgument]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveMakePoint [
	<inline: false>
	| rcvr arg pt |
	rcvr := self stackValue: 1.
	arg := self stackTop.
	(objectMemory isFloatOrInt: arg) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	pt := objectMemory eeInstantiateSmallClass: (objectMemory splObj: ClassPoint) numSlots: YIndex + 1.
	objectMemory "No need to check since new object is always new."
		storePointerUnchecked: XIndex ofObject: pt withValue: rcvr;
		storePointerUnchecked: YIndex ofObject: pt withValue: arg.
	self pop: 2 thenPush: pt
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveMarkHandlerMethod [
	"Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run."
	<inline: false>
	self primitiveFail
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveMarkUnwindMethod [
	"Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run.  It must also *not* allow a context switch."
	<inline: false>
	^self primitiveFail
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveMaxIdentityHash [
	self pop: 1 thenPushInteger: objectMemory maxIdentityHash
]

{ #category : #'plugin primitive support' }
InterpreterPrimitives >> primitiveMethod [
	"Return the method an external primitive was defined in"
	^newMethod
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveMillisecondClock [
	"Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger."

	self pop: 1 thenPush: (objectMemory integerObjectOf: (self ioMSecs bitAnd: MillisecondClockMask)).

]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveMillisecondClockMask [
	"Provide access to the millisecond clock mask to support calculation
	of durations based on the millisecond clock value."

	<export: true>
	self pop: 1 thenPush: (objectMemory integerObjectOf: MillisecondClockMask)

]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveMod [
	| mod |
	mod := self doPrimitiveMod: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: mod
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveModLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| result oopResult a aIsNegative b bIsNegative oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	b = 0 ifTrue:[self primitiveFail].
	self successful ifFalse:[^nil].

	result := a \\ b.

	"Handle remainder of same sign as argument"
	result = 0
		ifFalse: [bIsNegative = aIsNegative
			ifFalse: [result := b - result]].

	oopResult := self magnitude64BitIntegerFor: result neg: bIsNegative.
	self successful ifTrue: [self pop: 2 thenPush: oopResult].

]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveMouseButtons [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| buttonWord |
	self pop: 1.
	buttonWord := self ioGetButtonState.
	self pushInteger: buttonWord.
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveMousePoint [
	"Obsolete on virtually all platforms; old style input polling code.
	Return a Point indicating current position of the mouse. Note that mouse coordinates may be negative if the mouse moves above or to the left of the top-left corner of the Smalltalk window."

	| pointWord x y |
	pointWord := self ioMousePoint.
	x := self signExtend16: ((pointWord >> 16) bitAnd: 16rFFFF).
	y := self signExtend16: (pointWord bitAnd: 16rFFFF).
	self pop: 1 thenPush: (self makePointwithxValue: x  yValue: y)
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveMultiply [
	| integerRcvr integerArg integerResult overflow |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	self successful ifTrue:
		[overflow := integerRcvr > 0
					ifTrue:  [integerArg > 0
						ifTrue: [integerRcvr > (objectMemory maxSmallInteger / integerArg)]
						ifFalse: [integerArg < (objectMemory minSmallInteger / integerRcvr)]]
					ifFalse: [integerArg > 0
						ifTrue: [integerRcvr < (objectMemory minSmallInteger / integerArg)]
						ifFalse: [(integerRcvr < 0) and: [integerArg < (objectMemory maxSmallInteger / integerRcvr)]]].
		overflow
			ifTrue: [self primitiveFail]
			ifFalse:
				[integerResult := integerRcvr * integerArg.
				self pop: 2 thenPush: (objectMemory integerObjectOf: integerResult)]]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveMultiplyLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| a b result oopResult aIsNegative bIsNegative oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	self successful ifFalse:[^nil].
	
	"check for overflow"
	(a > 1 and: [b > 1 and: [a > (16rFFFFFFFFFFFFFFFF / b)]])
		ifTrue: [self primitiveFail. ^nil].

	result := a * b.
	oopResult := self magnitude64BitIntegerFor: result neg: aIsNegative ~= bIsNegative.

	self successful ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNew [
	NewspeakVM ifTrue: "For the mirror prims check that the class obj is actually a valid class."
		[(argumentCount < 1
		  or: [self objCouldBeClassObj: self stackTop]) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument]].
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			["Allocate a new fixed-size instance.  Fail if the allocation would leave
			  less than lowSpaceThreshold bytes free. This *will not* cause a GC :-)"
			(objectMemory instantiateClass: self stackTop)
				ifNotNil: [:obj| self pop: argumentCount + 1 thenPush: obj]
				ifNil: [self primitiveFailFor: ((objectMemory isFixedSizePointerFormat: (objectMemory instSpecOfClass: self stackTop))
											ifTrue: [PrimErrNoMemory]
											ifFalse: [PrimErrBadReceiver])]]
		ifFalse:
			["Allocate a new fixed-size instance. Fail if the allocation would leave
			  less than lowSpaceThreshold bytes free. May cause a GC."
			| spaceOkay |
			"The following may cause GC! Use var for result to permit inlining."
			spaceOkay := objectMemory
								sufficientSpaceToInstantiate: self stackTop
								indexableSize: 0.
			spaceOkay
				ifTrue:
					[self
						pop: argumentCount + 1
						thenPush: (objectMemory
									instantiateClass: self stackTop
									indexableSize: 0)]
				ifFalse: [self primitiveFailFor: PrimErrNoMemory]]
]

{ #category : #'compiled methods' }
InterpreterPrimitives >> primitiveNewMethod [
	| header bytecodeCount class size theMethod literalCount |
	header := self stackTop.
	bytecodeCount := self stackValue: 1.
	((objectMemory isIntegerObject: header)
	 and: [(objectMemory isIntegerObject: bytecodeCount)
	 and: [(bytecodeCount := objectMemory integerValueOf: bytecodeCount) >= 0]]) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^self].
	class := self stackValue: 2.
	literalCount := objectMemory literalCountOfMethodHeader: header.
	size := literalCount + LiteralStart * objectMemory bytesPerOop + bytecodeCount.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[theMethod := objectMemory instantiateCompiledMethodClass: class indexableSize: size.
			 theMethod ifNil:
				[self primitiveFailFor: ((objectMemory isCompiledMethodFormat: (objectMemory instSpecOfClass: class))
										ifTrue: [PrimErrNoMemory]
										ifFalse: [PrimErrBadReceiver]).
				 ^self]]
		ifFalse:
			[theMethod := objectMemory instantiateClass: class indexableSize: size].
	objectMemory storePointerUnchecked: HeaderIndex ofObject: theMethod withValue: header.
	1 to: literalCount do:
		[:i | objectMemory storePointer: i ofObject: theMethod withValue: objectMemory nilObject].
	self pop: 3 thenPush: theMethod
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNewWithArg [
	"Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC."
	| size spaceOkay instSpec |
	NewspeakVM ifTrue: "For the mirror prims check that the class obj is actually a valid class."
		[(argumentCount < 2
		  or: [self addressCouldBeClassObj: (self stackValue: 1)]) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument]].
	size := self positiveMachineIntegerValueOf: self stackTop.
	self successful ifFalse:"positiveMachineIntegerValueOf: succeeds only for non-negative integers."
		[^self primitiveFailFor: PrimErrBadArgument].
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[(objectMemory instantiateClass: (self stackValue: 1) indexableSize: size)
				ifNotNil: [:obj| self pop: argumentCount + 1 thenPush: obj]
				ifNil: [instSpec := objectMemory instSpecOfClass: (self stackValue: 1).
					  self primitiveFailFor: (((objectMemory isIndexableFormat: instSpec)
											and: [(objectMemory isCompiledMethodFormat: instSpec) not])
												ifTrue: [PrimErrNoMemory]
												ifFalse: [PrimErrBadReceiver])]]
		ifFalse:
			[spaceOkay := objectMemory sufficientSpaceToInstantiate: (self stackValue: 1) indexableSize: size.
			 spaceOkay
				ifTrue:
					[self
						pop: argumentCount + 1
						thenPush: (objectMemory instantiateClass: (self stackValue: 1) indexableSize: size)]
				ifFalse:
					[self primitiveFailFor: PrimErrNoMemory]]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNextInstance [
	| object subsequentObject |
	object := self stackTop.
	(objectMemory isImmediate: object) ifFalse:
		[subsequentObject := objectMemory instanceAfter: object.
		 subsequentObject ifNotNil:
			[^self pop: argumentCount+1 thenPush: subsequentObject]].
	self primitiveFail
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNextObject [
	"Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects."

	(objectMemory accessibleObjectAfter: self stackTop)
		ifNil: [self pop: argumentCount+1 thenPushInteger: 0]
		ifNotNil: [:instance|
			self assert: (objectMemory isInMemory: instance).
			self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveNoop [
	"A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver."

	self pop: argumentCount.  "pop args, leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveNotEqual [
	| integerReceiver integerArgument result |
	integerArgument := self stackTop.
	integerReceiver := self stackValue: 1.
	(objectMemory areIntegers: integerReceiver and: integerArgument)
		ifTrue: [self pop: 2 thenPushBool: integerReceiver ~= integerArgument]
		ifFalse:
			[result := objectMemory hasSixtyFourBitImmediates
						ifTrue:
							[(self signedMachineIntegerValueOf: integerReceiver)
								~= (self signedMachineIntegerValueOf: integerArgument)]
						ifFalse:
							[(self positiveMachineIntegerValueOf: integerReceiver)
								~= (self positiveMachineIntegerValueOf: integerArgument)].
			 self successful ifTrue:
				[self pop: 2 thenPushBool: result]]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveNotEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr ~= integerArg]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNotIdentical [
	"is the receiver/first argument not the same object as the (last) argument?.
	 pop argumentCount because this can be used as a mirror primitive."
	| thisObject otherObject |
	otherObject := self stackValue: 1.
	thisObject := self stackTop.
	(objectMemory isOopForwarded: otherObject) ifTrue:
		[self assert: argumentCount > 1.
		 otherObject := objectMemory followForwarded: thisObject].
	(objectMemory isOopForwarded: thisObject) ifTrue:
		[thisObject := objectMemory followForwarded: thisObject].
	self pop: argumentCount + 1 thenPushBool: thisObject ~= otherObject
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveObjectAt [
"Defined for CompiledMethods only"
	| thisReceiver index |
	index  := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	thisReceiver := self stackValue: 1.
	(index > 0 and: [index <= ((objectMemory literalCountOf: thisReceiver) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	self pop: 2 thenPush: (objectMemory fetchPointer: index - 1 ofObject: thisReceiver)
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveObjectAtPut [
	"Store a literal into a CompiledMethod at the given index. Defined for CompiledMethods only."
	| thisReceiver index newValue |
	newValue := self stackValue: 0.
	index := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [index = ConstOne and: [(objectMemory isNonIntegerObject: newValue)]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	thisReceiver := self stackValue: 2.
	(objectMemory isObjImmutable: thisReceiver) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	(index > 0 and: [index <= ((objectMemory literalCountOf: thisReceiver) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	objectMemory storePointer: index - 1 ofObject: thisReceiver withValue: newValue.
	self pop: 3 thenPush: newValue
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveObjectPointsTo [
	| rcvr thang lastField |
	thang := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isIntegerObject: rcvr) ifTrue:
		[^self pop: 2 thenPushBool: false].

	lastField := self lastPointerOf: rcvr.
	objectMemory baseHeaderSize to: lastField by: objectMemory bytesPerOop do:
		[:i |
		(objectMemory longAt: rcvr + i) = thang ifTrue:
			[^self pop: 2 thenPushBool: true]].
	self pop: 2 thenPushBool: false
]

{ #category : #'other primitives' }
InterpreterPrimitives >> primitivePathToUsing [
	"primitivePathTo: anObject using: stack <Array> followWeak: boolean
	 Answer a path to anObject from the root that does not pass through
	 the current context"
	| err path |
	<export: true>
	self externalWriteBackHeadFramePointers.
	argumentCount >= 2 ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	(self stackTop = objectMemory trueObject
	 or: [self stackTop = objectMemory falseObject]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	err := self pathTo: (self stackValue: 2)
				using: (self stackValue: 1)
				followWeak: self stackTop = objectMemory trueObject.
	err ~= 0 ifTrue:
		[^self primitiveFailFor: err].
	path := self self stackValue: 1.
	self pop: argumentCount + 1 thenPush: path
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitivePerformInSuperclass [
	| lookupClass rcvr currentClass |
	rcvr := self stackValue: 3.
	lookupClass := self stackTop.
	(argumentCount > 3 "e.g. object:perform:withArguments:inClass:"
	 and: [objectMemory isOopForwarded: rcvr]) ifTrue:
		[^self primitiveFail].
	currentClass := objectMemory fetchClassOf: rcvr.
	[currentClass ~= lookupClass] whileTrue:
		[currentClass := self superclassOf: currentClass.
		 currentClass = objectMemory nilObject ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument]].

	self primitiveObject: rcvr "a.k.a. self stackValue: 3"
		perform: (self stackValue: 2)
		withArguments: (self stackValue: 1)
		lookedUpIn: lookupClass "a.k.a. self stackTop"
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitivePerformWithArgs [
	self primitiveObject: (self stackValue: 2)
		perform: (self stackValue: 1)
		withArguments: self stackTop
		lookedUpIn: nil
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitivePin [
	"Pin or unpin the receiver, i.e. make it immobile or mobile, based on the argument.
	 Answer whether the object was already pinned. N.B. pinning does *not* prevent
	 an object from being garbage collected."
	<option: #SpurObjectMemory>
	| obj boolean wasPinned |

	obj := self stackValue: 1.
	((objectMemory isImmediate: obj)
	 or: [objectMemory isForwarded: obj]) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].

	boolean := self stackTop.
	(boolean = objectMemory falseObject
	 or: [boolean = objectMemory trueObject]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	(objectMemory isPinned: obj)
		ifTrue:
			[wasPinned := objectMemory trueObject.
			 boolean ~= wasPinned ifTrue:
				[objectMemory setIsPinnedOf: obj to: false]]
		ifFalse:
			[wasPinned := objectMemory falseObject.
			 (boolean ~= wasPinned
			  and: [(objectMemory pinObject: obj) = 0]) ifTrue:
				[^self primitiveFailFor: PrimErrNoMemory]].
	
	self pop: argumentCount + 1 thenPush: wasPinned
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveProcessBindToThreadId [
	"Simulation only.  Fail."
	<doNotGenerate>
	self primitiveFail
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveProcessBoundThreadId [
	"Simulation only.  Fail."
	<doNotGenerate>
	self primitiveFail
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveProfilePrimitive [
	"Primitive. Answer the last primitive method sampled by the profiler."
	<export: true>
	self methodArgumentCount = 0 ifFalse:
		[^self primitiveFail].
	self pop: 1 thenPush: profileMethod.
	profileMethod := objectMemory nilObject
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveProfileSample [
	"Primitive. Answer the last sample taken by the profiler, or nil if the profiler isn't active.
	See also primitiveProfileStart."
	<export: true>
	self methodArgumentCount = 0 ifFalse:
		[^self primitiveFail].
	self pop: 1 thenPush: profileProcess.
	profileProcess := objectMemory nilObject
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveProfileSemaphore [
	"Primitive. Install the semaphore to be used for profiling, 
	or nil if no semaphore should be used.
	See also primitiveProfileStart."
	| sema |
	<export: true>
	self methodArgumentCount = 1 ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	sema := self stackValue: 0.
	(sema = objectMemory nilObject
	 or: [objectMemory isSemaphoreOop: sema]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	profileSemaphore := sema.
	profileProcess := profileMethod := objectMemory nilObject.
	self pop: 1
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveProfileStart [
	"Primitive. Begin profiling execution every by using the interrupt check-counter instead of a time-based process (which is limited to timing resolution and triggers off the same signal that many of the processes being profiled trigger off leading to consistently wrong results).
	The argument is the number of interrupt checks (method activations) to let go by before taking a sample. The sample is being stored in the profileSample iVar which can be retrieved by executing primitiveProfileSample. When a sample is taken, it signals the semaphore specified in primitiveProfileSemaphore.
	If the argument is less or equal to zero, it disables profiling."
	| deltaTicks |
	<export: true>
	self methodArgumentCount = 1 ifFalse:[^self success: false].
	deltaTicks := self stackIntegerValue: 0.
	self successful ifTrue:[
		nextProfileTick := self ioHighResClock + deltaTicks.
		self pop: 1.
	]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveQuit [

	self ioExitWithErrorCode: (argumentCount = 1 ifTrue: [objectMemory integerValueOf: self stackTop] ifFalse: [0])
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveQuo [
	"Rounds negative results towards zero."
	| integerRcvr integerArg integerResult |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	self success: integerArg ~= 0.
	self successful ifTrue:
		[integerResult := self quot: integerRcvr ient: integerArg].
	self pop2AndPushIntegerIfOK: integerResult
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveQuoLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| result oopResult a aIsNegative b bIsNegative oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	b = 0 ifTrue:[self primitiveFail].
	self successful ifFalse:[^nil].

	result := a // b.

	oopResult := self magnitude64BitIntegerFor: result neg: bIsNegative ~= aIsNegative.
	self successful ifTrue: [self pop: 2 thenPush: oopResult].
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveRelinquishProcessor [
	"Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent."

	| microSecs |
	microSecs := self stackIntegerValue: 0.
	self successful ifTrue: [
		"DO NOT allow relinquishing the processor while we are profiling since this
		may skew the time base for our measures (it may reduce processor speed etc).
		Instead we go full speed, therefore measuring the precise time we spend in the
		inner idle loop as a busy loop."
		nextProfileTick = 0 ifTrue:[self ioRelinquishProcessorForMicroseconds: microSecs].
		self pop: 1.  "microSecs; leave rcvr on stack"
	]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveRemLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| result oopResult a aIsNegative b oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	b = 0 ifTrue:[self primitiveFail].
	self successful ifFalse:[^nil].

	result := a \\ b.

	oopResult := self magnitude64BitIntegerFor: result neg: aIsNegative.
	self successful ifTrue: [self pop: 2 thenPush: oopResult].
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveResume [
	"Put this process on the scheduler's lists thus allowing it to proceed next time there is
	 a chance for processes of it's priority level.  It must go to the back of its run queue so
	 as not to preempt any already running processes at this level.  If the process's priority
	 is higher than the current process, preempt the current process."
	| proc |
	proc := self stackTop.  "rcvr"
	(objectMemory isContext: (objectMemory fetchPointer: SuspendedContextIndex ofObject: proc)) ifFalse:
		[^self primitiveFail].
	self resume: proc preemptedYieldingIf: preemptionYields

	"Personally I would like to check MyList, which should not be one of the elements of the scheduler lists.
	 But there are awful race conditions in things like should:notTakeMoreThan: that mean we can't.
	 eem 9/27/2010 23:08. e.g.

	| proc myList classLinkedList |
	proc := self stackTop.
	myList := objectMemory fetchPointer: MyListIndex ofObject: proc.
	classLinkedList := self superclassOf: (objectMemory splObj: ClassSemaphore).
	((self fetchClassOfNonInt: myList) ~= classLinkedList
	and: [objectMemory isContext: (objectMemory fetchPointer: SuspendedContextIndex ofObject: proc)]) ifFalse:
		[^self primitiveFail].
	self resume: proc preemptedYieldingIf: preemptionYields"
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveRootTable [
	"Primitive. Answer a copy (snapshot) element of the root table.
	The primitive can cause GC itself and if so the return value may
	be inaccurate - in this case one should guard the read operation
	by looking at the gc counter statistics."
	<option: #SqueakV3ObjectMemory>
	self pop: argumentCount + 1 thenPush: objectMemory rootTableObject
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveRootTableAt [
	"Primitive. Answer the nth element of the root table.
	This primitive avoids the creation of an extra array;
	it is intended for enumerations of the form:
		index := 1.
		[root := Smalltalk rootTableAt: index.
		root == nil] whileFalse:[index := index + 1].
	"
	<export: true>
	<option: #SqueakV3ObjectMemory>
	| index |
	index := self stackIntegerValue: 0.
	self success: (index > 0 and:[index <= objectMemory rootTableCount]).
	self successful ifTrue:[
		self pop: argumentCount + 1.
		self push: (objectMemory rootTable at: index).
	]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveScanCharacters [
	"The character scanner primitive."
	| kernDelta stops sourceString scanStopIndex scanStartIndex rcvr scanDestX scanLastIndex scanXTable
	  scanMap maxGlyph ascii stopReason glyphIndex sourceX sourceX2 nextDestX scanRightX nilOop |

	self methodArgumentCount = 6
		ifFalse: [^ self primitiveFail].

	"Load the receiver and arguments"
	kernDelta := self stackIntegerValue: 0.
	stops := self stackValue: 1.
	scanRightX := self stackIntegerValue: 2.
	sourceString := self stackValue: 3.
	scanStopIndex := self stackIntegerValue: 4.
	scanStartIndex := self stackIntegerValue: 5.
	rcvr := self stackValue: 6.
	self successful ifFalse: [^ nil].
	
	"check argument type and range and rcvr"
	((objectMemory isArray: stops)
	 and: [(objectMemory slotSizeOf: stops) >= 258
	 and: [(objectMemory isBytes: sourceString)
	 and: [scanStartIndex > 0
	 and: [scanStopIndex > 0
	 and: [scanStopIndex <= (objectMemory byteSizeOf: sourceString)
	 and: [(objectMemory isPointers: rcvr)
	 and: [(objectMemory slotSizeOf: rcvr) >= 4]]]]]]])
		ifFalse: [^ self primitiveFail].

	"Check required rcvr instVars"
	scanDestX := self fetchInteger: 0 ofObject: rcvr.
	scanLastIndex := self fetchInteger: 1 ofObject: rcvr.
	scanXTable := objectMemory fetchPointer: 2 ofObject: rcvr.
	scanMap := objectMemory fetchPointer: 3 ofObject: rcvr.
	((objectMemory isArray: scanXTable)
	 and: [(objectMemory isArray: scanMap)
	 and: [(objectMemory slotSizeOf: scanMap) = 256
	 and: [self successful "for the fetchInteger:ofObject:'s above"]]]) ifFalse:
		[^ self primitiveFail].
	maxGlyph := (objectMemory slotSizeOf: scanXTable) - 2.

	"Okay, here we go. We have eliminated nearly all failure 
	conditions, to optimize the inner fetches."
	scanLastIndex := scanStartIndex.
	nilOop := objectMemory nilObject.
	[scanLastIndex <= scanStopIndex]
		whileTrue: [
			"Known to be okay since scanStartIndex > 0 and scanStopIndex <= sourceString size"
			ascii := objectMemory fetchByte: scanLastIndex - 1 ofObject: sourceString.
			"Known to be okay since stops size >= 258"
			(stopReason := objectMemory fetchPointer: ascii ofObject: stops) = nilOop
				ifFalse: ["Store everything back and get out of here since some stop conditionn needs to be checked"
					(objectMemory isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
					self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
					self storeInteger: 1 ofObject: rcvr withValue: scanLastIndex.
					self pop: 7 "args+rcvr" thenPush: stopReason.
					^nil].
			"Known to be okay since scanMap size = 256"
			glyphIndex := self fetchInteger: ascii ofObject: scanMap.
			"fail if the glyphIndex is out of range"
			(self failed or: [glyphIndex < 0 	or: [glyphIndex > maxGlyph]]) ifTrue: [^ self primitiveFail].
			sourceX := self fetchInteger: glyphIndex ofObject: scanXTable.
			sourceX2 := self fetchInteger: glyphIndex + 1 ofObject: scanXTable.
			"Above may fail if non-integer entries in scanXTable"
			self failed ifTrue: [^ nil].
			nextDestX := scanDestX + sourceX2 - sourceX.
			nextDestX > scanRightX ifTrue:
				["Store everything back and get out of here since we got to the right edge"
				(objectMemory isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
				self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
				self storeInteger: 1 ofObject: rcvr withValue: scanLastIndex.
				self pop: 7 "args+rcvr" thenPush: (objectMemory fetchPointer: CrossedX - 1 ofObject: stops).
				^nil].
			scanDestX := nextDestX + kernDelta.
			scanLastIndex := scanLastIndex + 1].
	(objectMemory isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
	self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
	self storeInteger: 1 ofObject: rcvr withValue: scanStopIndex.
	self pop: 7 "args+rcvr" thenPush: (objectMemory fetchPointer: EndOfRun - 1 ofObject: stops)
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveScreenDepth [
	"Return a SmallInteger indicating the current depth of the OS screen. Negative values are used to imply LSB type pixel format an there is some support in the VM for handling either MSB or LSB"
	| depth |
	<export: true>
	depth := self ioScreenDepth.
	self failed ifTrue:[^self primitiveFail].
	self pop: 1 thenPushInteger: depth.
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveScreenScaleFactor [
	"Answer a float indicating the current scale factor for pixels of the Smalltalk window."
	| factor |
	<export: true>
	<var: #factor type: #double>
	factor := self ioScreenScaleFactor.
	self failed ifTrue:[^self primitiveFail].
	self pop: 1; pushFloat: factor.
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveScreenSize [
	"Answer a point indicating the current size of the Smalltalk window.
	 Currently there is a limit of 65535 in each direction because the
	 point is encoded into a single 32bit value in the image header.
	 This might well become a problem one day"
	| pointWord |
	pointWord := self ioScreenSize.
	self pop: 1
		thenPush: (self makePointwithxValue: (pointWord >> 16 bitAnd: 65535)
						yValue: (pointWord bitAnd: 65535))
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveSecondsClock [
	"Return the number of seconds since January 1, 1901 as an integer."

	self pop: 1 thenPush: (self positive32BitIntegerFor: self ioSecondsNow)
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveSetDisplayMode [
	"Set to OS to the requested display mode.
	See also DisplayScreen setDisplayDepth:extent:fullscreen:"
	| fsFlag h w d okay |
	fsFlag := self booleanValueOf: (self stackTop).
	h := self stackIntegerValue: 1.
	w := self stackIntegerValue: 2.
	d := self stackIntegerValue: 3.
	self successful ifTrue: [okay := self cCode:'ioSetDisplayMode(w, h, d, fsFlag)'].
	self successful ifTrue: [self pop: 5 thenPushBool: okay "Pop args+rcvr"]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveSetFullScreen [
	"On platforms that support it, set full-screen mode to the value of the boolean argument."

	| argOop |
	argOop := self stackTop.
	argOop = objectMemory trueObject
		ifTrue: [self ioSetFullScreen: true]
		ifFalse: [ argOop = objectMemory falseObject
				ifTrue: [self ioSetFullScreen: false]
				ifFalse: [self primitiveFail]].
	self successful ifTrue: [self pop: 1]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveSetGCBiasToGrow [
	"Primitive. Indicate if the GC logic should have bias to grow"
	| flag |
	<export: true>
	<option: #SqueakV3ObjectMemory> "for now..."
	flag := self stackIntegerValue: 0.
	self successful ifTrue:[
		objectMemory gcBiasToGrow: flag.
		self pop: argumentCount.
	]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveSetGCBiasToGrowGCLimit [
	"Primitive. If the GC logic has  bias to grow, set growth limit"
	| value |
	<export: true>
	<option: #SqueakV3ObjectMemory> "for now..."
	value := self stackIntegerValue: 0.
	self successful ifTrue:
		[objectMemory gcBiasToGrowGCLimit: value.
		 objectMemory gcBiasToGrowThreshold: objectMemory youngStart - objectMemory startOfMemory asInteger.
		 self pop: argumentCount]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSetIdentityHash [
	| hash oldHash thisReceiver |
	hash := self stackIntegerValue: 0.
	thisReceiver := self stackObjectValue: 1.
	self successful ifTrue:
		[oldHash := objectMemory hashBitsOf: thisReceiver.
		 objectMemory setHashBitsOf: thisReceiver to: hash.
		 self pop: argumentCount + 1 thenPushInteger: oldHash]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSetImmutability [
	<option: #IMMUTABILITY>
	| rcvr wasImmutable |
	 rcvr := self stackValue: 1.
	 (objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	 wasImmutable := objectMemory isObjImmutable: rcvr.
	 self stackTop = objectMemory trueObject
		ifTrue:
			[(self canBeImmutable: rcvr) ifFalse:
				[^self primitiveFailFor: PrimErrInappropriate].
			  objectMemory setIsImmutableOf: rcvr to: true]
		ifFalse: [
	self stackTop = objectMemory falseObject
		ifTrue: [objectMemory setIsImmutableOf: rcvr to: false]
	 	ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument]].
	 self pop: argumentCount + 1 thenPushBool: wasImmutable
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveSetInterruptKey [
	"Set the user interrupt keycode. The keycode is an integer whose encoding is described in the comment for primitiveKbdNext."

	| keycode |
	keycode := self stackIntegerValue: 0.
	self successful ifTrue:
		[self setInterruptKeycode: keycode.
		 self pop: argumentCount]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveSetLogDirectory [
	"Primitive. Set the VM's log directory"
	| stringOop sz |
	<export: true>
	stringOop := self stackTop.
	(objectMemory isBytes: stringOop) ifFalse:[^self success: false].
	sz := objectMemory byteSizeOf: stringOop.
	self ioSetLogDirectory: (objectMemory firstIndexableField: stringOop) OfSize: sz.
	self successful ifTrue:[self pop: self methodArgumentCount]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSetOrHasIdentityHash [
	| hash oldHash thisReceiver isReceiverAClass |
	argumentCount = 0 ifTrue:
		[| hasHash |
		 hasHash := (objectMemory isNonImmediate: self stackTop)
						and: [objectMemory hasIdentityHash: self stackTop].
		 self pop: argumentCount + 1 thenPushBool: hasHash.
		 ^self].
	argumentCount = 2 
		ifTrue: 
			[isReceiverAClass := self booleanValueOf: self stackTop.
			self successful ifFalse: [self primitiveFailFor: PrimErrBadArgument] ]
		ifFalse: [isReceiverAClass := false].
	hash := self stackIntegerValue: argumentCount - 1.
	thisReceiver := self stackObjectValue: argumentCount.
	self successful ifTrue:
		[oldHash := objectMemory hashBitsOf: thisReceiver.
		 objectMemory setHashBitsOf: thisReceiver to: hash.
		(isReceiverAClass and: [objectMemory hasSpurMemoryManagerAPI]) ifTrue:
				[objectMemory classAtIndex: hash put: thisReceiver.
				"next line figures out if the index is anbiguous and fix all the instances if needed"
				objectMemory allInstancesOf: thisReceiver].
		 self pop: argumentCount + 1 thenPushInteger: oldHash]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveSetWindowLabel [
	"Primitive. Set the OS window's label"
	| labelOop sz |
	<export: true>
	labelOop := self stackTop.
	(objectMemory isBytes: labelOop) ifFalse:[^self success: false].
	sz := objectMemory byteSizeOf: labelOop.
	self ioSetWindowLabel: (objectMemory firstIndexableField: labelOop) OfSize: sz.
	self successful ifTrue:[self pop: self methodArgumentCount]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveSetWindowSize [
	"Primitive. Answer the OS window's size (extent)"
	| w h |
	<export: true>
	h := self stackIntegerValue: 0.
	w := self stackIntegerValue: 1.
	self successful ifTrue:[
		self ioSetWindowWidth: w Height: h.
		self pop: self methodArgumentCount.
	]
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveShortAt [
	"Treat the receiver, which can be indexible by either bytes or words, as
	 an array of signed 16-bit values. Answer the contents of the given index.
	 Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr value |
	index := self stackTop.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	(objectMemory isWordsOrBytes: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := objectMemory integerValueOf: index.
	((index >= 1) and: [index <= (objectMemory num16BitUnitsOf: rcvr)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	value := objectMemory fetchShort16: index - 1 ofObject: rcvr.
	self cCode: []
		inSmalltalk: [value > 32767 ifTrue: [value := value - 65536]].
	self pop: 2 thenPushInteger: value
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveShortAtPut [
	"Treat the receiver, which can be indexible by either bytes or words, as an array
	 of signed 16-bit values. Set the contents of the given index to the given value.
	 Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr value |
	value := self stackTop.
	index := self stackValue: 1.
	((objectMemory isIntegerObject: value)
	 and: [(objectMemory isIntegerObject: index)
	 and: [value := objectMemory integerValueOf: value.
		  (value >= -32768) and: [value <= 32767]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	(objectMemory isWordsOrBytes: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	index := objectMemory integerValueOf: index.
	(index >= 1 and: [index <= (objectMemory num16BitUnitsOf: rcvr)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	objectMemory storeShort16: index - 1 ofObject: rcvr withValue: value.
	self pop: 3 thenPush: (objectMemory integerObjectOf: value)
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveShowDisplayRect [
	"Force the given rectangular section of the Display to be 
	copied to the screen."
	| bottom top right left |
	bottom := self stackIntegerValue: 0.
	top := self stackIntegerValue: 1.
	right := self stackIntegerValue: 2.
	left := self stackIntegerValue: 3.
	self updateDisplayLeft: left Top: top Right: right Bottom: bottom.
	self successful ifTrue:
		[self ioForceDisplayUpdate.
		 self pop: 4]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveSignal [
	"Synchronously signal the semaphore.
	 This may change the active process as a result."
	self synchronousSignal: self stackTop
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveSignalAtBytesLeft [
	"Set the low-water mark for free space. When the free space falls
	 below this level, the new and new: primitives fail and system attempts
	 to allocate space (e.g., to create a method context) cause the low-space
	 semaphore (if one is registered) to be signalled."
	| bytes |
	bytes := self stackTop.
	((objectMemory isIntegerObject: bytes)
	 and: [(bytes := objectMemory integerValueOf: bytes) >= 0])
		ifTrue: [objectMemory lowSpaceThreshold: bytes. self pop: 1]
		ifFalse: [self primitiveFailFor: PrimErrBadArgument]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSine [
	"N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		[self stackTopPut: (objectMemory floatObjectOf:
								(self cCode: [rcvr sin]
									inSmalltalk: [rcvr = rcvr
													ifTrue: [rcvr sin]
													ifFalse: [Float nan]]))]
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveSize [
	<accessorDepth: 0>
	| rcvr hdr fmt fixedFields totalLength |
	rcvr := self stackTop.
	((objectMemory isImmediate: rcvr) "Integers are not indexable"
	 or: [hdr := objectMemory baseHeader: rcvr.
		(fmt := objectMemory formatOfHeader: hdr) < 2]) "This is not an indexable object"
		ifTrue:
			[^self primitiveFailFor: PrimErrBadReceiver].
	(fmt = objectMemory indexablePointersFormat
	 and: [objectMemory isContextHeader: hdr]) ifTrue:
		[^self primitiveContextSize].
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: totalLength - fixedFields)
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveSizeInBytes [
	<option: #SpurObjectMemory>
	| byteSize |
	byteSize := objectMemory totalByteSizeOf: self stackTop.
	self pop: argumentCount + 1
		 thenPush: (self positive64BitIntegerFor: byteSize)
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveSizeInBytesOfInstance [
	"Answer the byte size of an instance of the receiver.  If num args > 0
	 then the last argument is a variable size and the size answered is the
	 size of an instance of the receiver with that many indexable elements."
	<option: #SpurObjectMemory>
	| byteSize err |
	NewspeakVM
		ifTrue: "Support VMMirror>>byteSizeOfInstanceOf:WithIndexableVariables:"
			[argumentCount > 2 ifTrue:
				[^self primitiveFailFor: PrimErrBadNumArgs]]
		ifFalse:
			[argumentCount > 1 ifTrue:
				[^self primitiveFailFor: PrimErrBadNumArgs]].
	err := -1.
	argumentCount >= 1 ifTrue:
		[(objectMemory isIntegerObject: self stackTop) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument].
		 byteSize := objectMemory
						byteSizeOfInstanceOf: (self stackValue: 1)
						withIndexableSlots: (objectMemory integerValueOf: self stackTop)
						errInto: [:code| err := code].
		 err >= 0 ifTrue:
			[^self primitiveFailFor: err].
		 ^self pop: argumentCount + 1 thenPush: (self positive64BitIntegerFor: byteSize)].
	byteSize := objectMemory
						byteSizeOfInstanceOf: (self stackValue: 0)
						errInto: [:code| err := code].
	err >= 0 ifTrue:
		[^self primitiveFailFor: err].
	self pop: 1 thenPushInteger: byteSize
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSlotAt [
	"Answer a slot in an object.  This numbers all slots from 1, ignoring the distinction between
	 named and indexed inst vars.  In objects with both named and indexed inst vars, the named
	 inst vars precede the indexed ones.  In non-object indexed objects (objects that contain
	 bits, not object references) this primitive answers the raw integral value at each slot. 
	 e.g. for Strings it answers the character code, not the Character object at each slot."
	| index rcvr fmt numSlots |
	index := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	fmt := objectMemory formatOf: rcvr.
	index := (objectMemory integerValueOf: index) - 1.

	fmt <= objectMemory lastPointerFormat ifTrue:
		[numSlots := objectMemory numSlotsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1 thenPush: (objectMemory fetchPointer: index ofObject: rcvr).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstByteFormat ifTrue:
		[fmt >= objectMemory firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 numSlots := objectMemory numBytesOfBytes: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1 thenPushInteger: (objectMemory fetchByte: index ofObject: rcvr).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(objectMemory hasSpurMemoryManagerAPI
	 and: [fmt >= objectMemory firstShortFormat]) ifTrue:
		[numSlots := objectMemory num16BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1 thenPushInteger: (objectMemory fetchUnsignedShort16: index ofObject: rcvr).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
		[numSlots := objectMemory num64BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1
				thenPush: (self positive64BitIntegerFor: (objectMemory fetchLong64: index ofObject: rcvr)).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstLongFormat ifTrue:
		[numSlots := objectMemory num32BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1
				thenPush: (objectMemory bytesPerOop = 8
							ifTrue: [objectMemory integerObjectOf: (objectMemory fetchLong32: index ofObject: rcvr)]
							ifFalse: [self positive32BitIntegerFor: (objectMemory fetchLong32: index ofObject: rcvr)]).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	^self primitiveFailFor: PrimErrBadReceiver
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSlotAtPut [
	"Assign a slot in an object.  This numbers all slots from 1, ignoring the distinction between
	 named and indexed inst vars.  In objects with both named and indexed inst vars, the named
	 inst vars precede the indexed ones.  In non-object indexed objects (objects that contain
	 bits, not object references) this primitive assigns a raw integral value at each slot."
	| newValue index rcvr fmt numSlots value |
	newValue := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	fmt := objectMemory formatOf: rcvr.
	index := (objectMemory integerValueOf: index) - 1.

	fmt <= objectMemory lastPointerFormat ifTrue:
		[numSlots := objectMemory numSlotsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storePointer: index ofObject: rcvr withValue: newValue.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	value := self positiveMachineIntegerValueOf: newValue.
	self failed ifTrue:
		[primFailCode := PrimErrBadArgument.
		^0].

	fmt >= objectMemory firstByteFormat ifTrue:
		[fmt >= objectMemory firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 (self asUnsigned: value) > 16rFF ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory numBytesOfBytes: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeByte: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(objectMemory hasSpurMemoryManagerAPI
	 and: [fmt >= objectMemory firstShortFormat]) ifTrue:
		[(self asUnsigned: value) > 16rFFFF ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory num16BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeShort16: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(objectMemory bytesPerOop = 8
	 and: [fmt = objectMemory sixtyFourBitIndexableFormat]) ifTrue:
		[numSlots := objectMemory num64BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeLong64: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstLongFormat ifTrue:
		[(objectMemory wordSize > 4
		  and: [(self asUnsigned: value) > 16rFFFFFFFF]) ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory num32BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeLong32: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	^self primitiveFailFor: PrimErrBadReceiver
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatAdd [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr + arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatArctan [
	<option: #Spur64BitMemoryManager>
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := objectMemory smallFloatValueOf: self stackTop.
	self stackTopPut: (objectMemory floatObjectOf: (self cCode: [rcvr atan]
														inSmalltalk: [rcvr arcTan]))
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatDivide [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	arg = 0.0 ifTrue:
		[self primitiveFail].
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr / arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatEqual [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: rcvr = arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatExp [
	"Computes E raised to the receiver power.
	 Since SmallFloats cannot represent NaNs there's no need to special case."
	<option: #Spur64BitMemoryManager>

	self stackTopPut: (objectMemory floatObjectOf: (objectMemory smallFloatValueOf: self stackTop) exp)
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatExponent [
	"Answer the exponent part of this float."
	<option: #Spur64BitMemoryManager>

	self stackTopPut: (objectMemory integerObjectOf: (objectMemory exponentOfSmallFloat: self stackTop) - 1)
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatFractionalPart [
	<option: #Spur64BitMemoryManager>
	| rcvr frac trunc |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #trunc type: #double>
	rcvr := objectMemory smallFloatValueOf: self stackTop.
	frac := self cCode: [self mod: rcvr f: (self addressOf: trunc)]
				inSmalltalk: [rcvr fractionPart].
	self stackTopPut: (objectMemory floatObjectOf: frac)
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatGreaterOrEqual [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: rcvr >= arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatGreaterThan [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: rcvr > arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatHash [
	"Answer the ieee 754 double precision floating point bits of the SmallFloat receiver."
	<option: #Spur64BitMemoryManager>

	self pop: 1 thenPush: (objectMemory positive64BitIntegerFor: (objectMemory smallFloatBitsOf: self stackTop))
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatLessOrEqual [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: rcvr <= arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatLessThan [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: rcvr < arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatLogN [
	"Natural log."
	<option: #Spur64BitMemoryManager>
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := objectMemory smallFloatValueOf: self stackTop.
	self stackTopPut: (objectMemory floatObjectOf: (self cCode: [rcvr log] inSmalltalk: [rcvr ln]))
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatMultiply [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr * arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatNotEqual [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: (rcvr = arg) not]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatSine [
	<option: #Spur64BitMemoryManager>
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := objectMemory smallFloatValueOf: self stackTop.
	self stackTopPut: (objectMemory floatObjectOf: rcvr sin)
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatSquareRoot [
	<option: #Spur64BitMemoryManager>
	<var: #rcvr type: #double>
	| rcvr |
	rcvr := objectMemory smallFloatValueOf: self stackTop.
	rcvr >= 0.0
		ifTrue: [self stackTopPut: (objectMemory floatObjectOf: rcvr sqrt)]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatSubtract [
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := objectMemory loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr - arg]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatTimesTwoPower [
	"Multiply the receiver by the power of the argument."
	<option: #Spur64BitMemoryManager>
	| rcvr result arg twiceMaxExponent |
	arg := self stackTop.
	(objectMemory isIntegerObject: arg) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	"N.B. SmallFloats are finite.  NaN and Infinity overflow into boxed floats.
	 This is doing range checking work that is done in ldexp, but we include
	 it explicitly to exemplify bit manipulation of SmallFloats."
	(objectMemory isSmallFloatZero: rcvr)
		ifTrue:
			[result := rcvr]
		ifFalse:
			[arg := objectMemory integerValueOf: arg.
			 twiceMaxExponent := 2 * (1 << self floatExponentBits).
			 arg < twiceMaxExponent negated
				ifTrue:
					[result := objectMemory mapSignedSmallFloatToSignedSmallFloatZero: rcvr]
				ifFalse:
					["clip arg to at most int range; ldexp's last arg is of type int"
					 arg > twiceMaxExponent ifTrue: [arg := twiceMaxExponent].
					 result := objectMemory floatObjectOf: (self cCode: [self ld: (objectMemory smallFloatValueOf: rcvr)
																				exp: (self cCoerceSimple: arg to: #int)]
																inSmalltalk: [(objectMemory smallFloatValueOf: rcvr) timesTwoPower: arg])]].
	self pop: 2 thenPush: result
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSmallFloatTruncated [
	<option: #Spur64BitMemoryManager>
	| rcvr trunc |
	<var: #rcvr type: #double>
	<var: #trunc type: #double>
	rcvr := objectMemory smallFloatValueOf: self stackTop.
	self cCode: [self mod: rcvr f: (self addressOf: trunc)]
		inSmalltalk: [trunc := rcvr truncated].
	((trunc between: objectMemory minSmallInteger asFloat and: objectMemory maxSmallInteger asFloat)
	 and: [objectMemory isIntegerValue: trunc asInteger])
		ifTrue: [self stackTopPut: (objectMemory integerObjectOf: trunc asInteger)]
		ifFalse: [self primitiveFail]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveSnapshot [
	"save a normal snapshot under the same name as it was loaded unless it has been renamed by the last primitiveImageName"
	<inline: false>
	self snapshot: false

]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveSnapshotEmbedded [
	"save an embedded snapshot"
	<inline: false>
	self snapshot: true
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSomeInstance [
	| class instance |
	class := self stackTop.
	NewspeakVM ifTrue: "For the mirror prims check that the class obj is actually a valid class."
		[(argumentCount < 1
		  or: [(objectMemory isNonImmediate: class)
			  and: [self objCouldBeClassObj: class]]) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument]].
	instance := objectMemory initialInstanceOf: class.
	instance
		ifNil: [self primitiveFail]
		ifNotNil: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveSomeObject [
	"Return the first object in the heap."

	self pop: argumentCount+1.
	self push: objectMemory firstAccessibleObject.
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveSpecialObjectsOop [
	"Return the oop of the SpecialObjectsArray."

	self pop: 1 thenPush: objectMemory specialObjectsOop.
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveSpurIntegerAt [
	"Answer the signed integer element of a pure bits receiver.
	 If the receiver is indexable pointers simply function like at:.
	 Favour bits access over pointer access (normal at: being available)."

	<inline: true>
	| index rcvr fmt numSlots value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	fmt := objectMemory formatOf: rcvr.
	index := (objectMemory integerValueOf: index) - 1.

	fmt >= objectMemory firstByteFormat ifTrue:
		[fmt >= objectMemory firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 numSlots := objectMemory numBytesOfBytes: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[value := objectMemory fetchByte: index ofObject: rcvr.
			 value > 127 ifTrue: [value := value - 256].
			 self methodReturnInteger: value.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstShortFormat ifTrue:
		[numSlots := objectMemory num16BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[value := objectMemory fetchShort16: index ofObject: rcvr.
			 value > 32767 ifTrue: [value := value - 65536].
			 self methodReturnInteger: value.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
		[numSlots := objectMemory num64BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self
				cCode:
					[self methodReturnValue: (self signed64BitIntegerFor: (objectMemory fetchLong64: index ofObject: rcvr))]
				inSmalltalk:
					[value := objectMemory fetchLong64: index ofObject: rcvr.
					 value > ((2 raisedTo: 63) - 1) ifTrue:
						[value := value - (2 raisedTo: 64)].
					 self methodReturnValue: (self signed64BitIntegerFor: value)].
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstLongFormat ifTrue:
		[numSlots := objectMemory num32BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory bytesPerOop = 8
				ifTrue:
					[value := objectMemory fetchLong32: index ofObject: rcvr.
					 value > 2147483647 ifTrue: [value := value - 4294967296].
					 self methodReturnInteger: value]
				ifFalse: [self methodReturnValue: (self signed32BitIntegerFor: (objectMemory fetchLong32: index ofObject: rcvr))].
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(fmt <= objectMemory lastPointerFormat
	 and: [objectMemory isIndexableFormat: fmt]) ifTrue:
		[| numFixed |
		 numSlots := objectMemory numSlotsOf: rcvr.
		 fmt = objectMemory arrayFormat ifTrue:
			[(self asUnsigned: index) < numSlots ifTrue:
				[self methodReturnValue: (objectMemory fetchPointer: index ofObject: rcvr).
				 ^0]].
		 numFixed := self numFixedSlotsOf: rcvr.
		 (index + 1 between: numFixed and: numSlots) ifTrue:
			[self methodReturnValue: (objectMemory fetchPointer: index + numFixed ofObject: rcvr).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	^self primitiveFailFor: PrimErrBadReceiver
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveSpurIntegerAtPut [
	"Assign an indexable variable of a pure bits receiver with a signed integer.
	 If the receiver is indexable pointers simply function like at:put: primitive 61.
	 Favour bits access over pointer access (normal at:put: being available)."

	<inline: true>
	| index rcvr value valueOop fmt numSlots |
	valueOop := self stackValue: 0.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	value := self signed64BitValueOf: valueOop.
	(self successful
	 and: [objectMemory isIntegerObject: index]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	fmt := objectMemory formatOf: rcvr.
	index := (objectMemory integerValueOf: index) - 1.

	fmt >= objectMemory firstByteFormat ifTrue:
		[fmt >= objectMemory firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 (self isSignedInteger: value inRangeForBits: 8) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory numBytesOfBytes: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeByte: index ofObject: rcvr withValue: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFF]).
			 self methodReturnValue: valueOop.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstShortFormat ifTrue:
		[(self isSignedInteger: value inRangeForBits: 16) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory num16BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeShort16: index ofObject: rcvr withValue: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFFFF]).
			 self methodReturnValue: valueOop.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
		["No range check on value in this case because signed64BitValueOf: performed it above."
		 numSlots := objectMemory num64BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeLong64: index ofObject: rcvr withValue: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFFFFFFFFFFFFFFFF]).
			 self methodReturnValue: valueOop.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstLongFormat ifTrue:
		[(self isSignedInteger: value inRangeForBits: 32) ifFalse:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory num32BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeLong32: index ofObject: rcvr withValue: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFFFFFFFF]).
			 self methodReturnValue: valueOop.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(fmt <= objectMemory lastPointerFormat
	 and: [objectMemory isIndexableFormat: fmt]) ifTrue:
		[| numFixed |
		 numSlots := objectMemory numSlotsOf: rcvr.
		 fmt = objectMemory arrayFormat ifTrue:
			[(self asUnsigned: index) < numSlots ifTrue:
				[self storePointer: index ofObject: rcvr withValue: valueOop.
				 self methodReturnValue: valueOop.
				 ^0]].
		 numFixed := self numFixedSlotsOf: rcvr.
		 (index + 1 between: numFixed and: numSlots) ifTrue:
			[self storePointer: index + numFixed ofObject: rcvr withValue: valueOop.
			 self methodReturnValue: valueOop.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	^self primitiveFailFor: PrimErrBadReceiver
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveSpurStringReplace [
	"<array> primReplaceFrom: start to: stop with: replacement startingAt: repStart  
		<primitive: 105>"
	<inline: true>
	| array start stop repl replStart arrayFmt arrayLength arrayInstSize replFmt replLength replInstSize srcDelta |
	array := self stackValue: 4.
	start := self stackValue: 3.
	stop := self stackValue: 2.
	repl := self stackValue: 1.
	replStart := self stackValue: 0.

	((objectMemory isNonIntegerObject: start)
	 or: [(objectMemory isNonIntegerObject: stop)
	 or: [(objectMemory isNonIntegerObject: replStart)
	 or: [objectMemory isImmediate: repl]]]) ifTrue: "can happen in LgInt copy"
		[^self primitiveFailFor: PrimErrBadArgument].

	start := objectMemory integerValueOf: start.
	stop := objectMemory integerValueOf: stop.
	replStart := objectMemory integerValueOf: replStart.

	(stop >= start and: [objectMemory isObjImmutable: array]) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].

	arrayFmt := objectMemory formatOf: array.
	arrayLength := objectMemory lengthOf: array format: arrayFmt.
	arrayFmt := objectMemory classFormatFromInstFormat: arrayFmt.
	replFmt := objectMemory formatOf: repl.
	replLength := objectMemory lengthOf: repl format: replFmt.
	replFmt := objectMemory classFormatFromInstFormat: replFmt.

	"Array formats (without oddFields bits) must be the same"
	(arrayFmt = replFmt
	 and: [arrayFmt < objectMemory firstCompiledMethodFormat]) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].

	"N.B. In the below start - 1 to: stop - 1 do:, Slang is intelligent enough to use < instead of <= so avoiding the stop - 1."
	arrayFmt <= objectMemory lastPointerFormat
		ifTrue:
			[arrayInstSize := objectMemory fixedFieldsOf: array format: arrayFmt length: arrayLength.
			 replInstSize := objectMemory fixedFieldsOf: repl format: replFmt length: replLength.
			 (start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= arrayLength
			  and: [replStart >= 1 and: [stop - start + replStart + replInstSize <= replLength]]]]) ifFalse:
				[^self primitiveFailFor: PrimErrBadIndex].
			 start := start + arrayInstSize.
			 stop := stop + arrayInstSize.
			 srcDelta := (replStart + replInstSize) - start.
			 (objectMemory isOldObject: array)
				ifTrue:
					[| mustRemember oop |
					 mustRemember := false.
					 start - 1 to: stop - 1 do:
						[:i |
						oop := objectMemory fetchPointer: srcDelta + i ofObject: repl.
						(objectMemory isYoung: oop) ifTrue:
							[mustRemember := true].
						objectMemory storePointerUnchecked: i ofObject: array withValue: oop].
					 mustRemember ifTrue:
						[objectMemory possibleRootStoreInto: array]]
				ifFalse:
					[start - 1 to: stop - 1 do:
						[:i | objectMemory storePointerUnchecked: i ofObject: array withValue: (objectMemory fetchPointer: srcDelta + i ofObject: repl)]]]
		ifFalse:
			[(start >= 1 and: [start - 1 <= stop and: [stop <= arrayLength
			  and: [replStart >= 1 and: [stop - start + replStart <= replLength]]]]) ifFalse:
				[^self primitiveFailFor: PrimErrBadIndex].
			 srcDelta := replStart - start.
			 arrayFmt >= objectMemory firstShortFormat
				ifTrue: "8 & 16-bit word type objects"
					[arrayFmt >= objectMemory firstByteFormat
						ifTrue: "byte-type objects"
							[start - 1 to: stop - 1 do:
								[:i | objectMemory storeByte: i ofObject: array withValue: (objectMemory fetchByte: srcDelta + i ofObject: repl)]]
						ifFalse: "short type objects"
							[start - 1 to: stop - 1 do:
								[:i | objectMemory storeShort16: i ofObject: array withValue: (objectMemory fetchShort16: srcDelta + i ofObject: repl)]]]
				ifFalse: "32 & 64-bit word type objects"
					[arrayFmt >= objectMemory firstLongFormat
						ifTrue: "word-type objects"
							[start - 1 to: stop - 1 do:
								[:i | objectMemory storeLong32: i ofObject: array withValue: (objectMemory fetchLong32: srcDelta + i ofObject: repl)]]
						ifFalse: "long type objects"
							[start - 1 to: stop - 1 do:
								[:i | objectMemory storeLong64: i ofObject: array withValue: (objectMemory fetchLong64: srcDelta + i ofObject: repl)]]]].
	"We might consider comparing stop - start to some value here and using forceInterruptCheck"

	self pop: argumentCount "leave rcvr on stack"
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSquareRoot [
	"N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self stackFloatValue: 0.
	(self successful and: [rcvr >= 0.0])
		ifTrue: [self stackTopPut: (objectMemory floatObjectOf: rcvr sqrt)]
		ifFalse: [self primitiveFail]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveStartVMProfiling [
	"Primitive. Start the VM profiler."
	self cCode: 'ioControlProfile(1,0,0,0,0)'.
	self pop: argumentCount
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveStopVMProfiling [
	"Primitive. Stop the VM profiler and either copy the histogram data into the
	 supplied arguments, if they're non-nil.  Fail if the arguments are not of the right type or size."
	| vmHistArrayOrNil vmHist vmBins easHistArrayOrNil easHist easBins |
	<var: #vmHist type: #'long *'>
	<var: #vmBins type: #long>
	<var: #easHist type: #'long *'>
	<var: #easBins type: #long>
	self success: argumentCount = 2.
	vmHistArrayOrNil := self stackObjectValue: 1.
	easHistArrayOrNil := self stackObjectValue: 0.
	self successful ifFalse:
		[^nil].
	"Both args must be either nil or arrays.  If they're arrays and the wrong size we incorrectly stop profiling."
	((vmHistArrayOrNil = objectMemory nilObject or: [(objectMemory fetchClassOfNonImm: vmHistArrayOrNil) = (objectMemory splObj: ClassArray)])
	 and: [(objectMemory fetchClassOfNonImm: vmHistArrayOrNil) = (objectMemory fetchClassOfNonImm: easHistArrayOrNil)]) ifFalse:
		[^self primitiveFail].
	self cCode: 'ioControlProfile(0,&vmHist,&vmBins,&easHist,&easBins)'
		inSmalltalk: [vmHist := vmBins := easHist := easBins := 0].
	vmHistArrayOrNil ~= objectMemory nilObject ifTrue:
		[((objectMemory numSlotsOf: vmHistArrayOrNil) = vmBins
		  and: [(objectMemory numSlotsOf: easHistArrayOrNil) = easBins]) ifFalse:
			[^self primitiveFail].
		0 to: vmBins - 1 do:
			[:i|
			objectMemory storePointerUnchecked: i
				ofObject: vmHistArrayOrNil
				withValue: (objectMemory integerObjectOf: (vmHist at: i))].
		0 to: easBins - 1 do:
			[:i|
			objectMemory storePointerUnchecked: i
				ofObject: easHistArrayOrNil
				withValue: (objectMemory integerObjectOf: (easHist at: i))]].
	self pop: argumentCount
]

{ #category : #'image segment in/out' }
InterpreterPrimitives >> primitiveStoreImageSegment [
	"This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray."

"This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set."

"The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded."

	| outPointerArray segmentWordArray arrayOfRoots ecode |

	outPointerArray := self stackTop.
	segmentWordArray := self stackValue: 1.
	arrayOfRoots := self stackValue: 2.

	"Essential type checks"
	((objectMemory isArray: arrayOfRoots)				"Must be indexable pointers"
	and: [(objectMemory isArray: outPointerArray)		"Must be indexable pointers"
	and: [objectMemory isWords: segmentWordArray]])	"Must be indexable words"
		ifFalse: [^self primitiveFail].

	ecode := objectMemory storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots.
	(objectMemory hasSpurMemoryManagerAPI
	 and: [ecode = PrimErrNeedCompaction]) ifTrue:
		[objectMemory fullGC.
		 outPointerArray := self stackTop.
		 segmentWordArray := self stackValue: 1.
		 arrayOfRoots := self stackValue: 2.
		 ecode := objectMemory storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots].
	ecode = PrimNoErr
		ifTrue: [self pop: 3]  "...leaving the receiver on the stack as return value"
		ifFalse: [self primitiveFailFor: ecode]
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveStringAt [

	self commonAt: true.
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveStringAtPut [

	self commonAtPut: true.
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveStringReplace [
	"<array> primReplaceFrom: start to: stop with: replacement startingAt: repStart  
		<primitive: 105>"
	objectMemory hasSpurMemoryManagerAPI
		ifTrue: [self primitiveSpurStringReplace]
		ifFalse: [self primitiveV3StringReplace]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveSubtract [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) - (self stackIntegerValue: 0)
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveSubtractLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| a b result oopResult aIsNegative bIsNegative resultIsNegative oopArg oopRcvr |
	<export: true>
	<var: 'a' type: 'usqLong'>
	<var: 'b' type: 'usqLong'>
	<var: 'result' type: 'usqLong'>

	oopArg := self stackValue: 0.
	oopRcvr := self stackValue: 1.
	aIsNegative := self isNegativeIntegerValueOf: oopRcvr.
	bIsNegative := self isNegativeIntegerValueOf: oopArg.
	a := self magnitude64BitValueOf: oopRcvr.
	b := self magnitude64BitValueOf: oopArg.
	self successful ifFalse:[^nil].
	(aIsNegative ~= bIsNegative)
		ifTrue:
			["Protect against overflow"
			a > (16rFFFFFFFFFFFFFFFF - b) ifTrue: [self primitiveFail. ^nil].
			result := a + b.
			resultIsNegative := aIsNegative]
		ifFalse:
			[(a >= b)
				ifTrue:
					[result := a - b.
					resultIsNegative := aIsNegative]
				ifFalse:
					[result := b - a.
					resultIsNegative := aIsNegative not]].
	oopResult := self magnitude64BitIntegerFor: result neg: resultIsNegative.
	self successful ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveSuspend [
	"Primitive. Suspend the receiver, aProcess such that it can be executed again
	by sending #resume. If the given process is not currently running, take it off
	its corresponding list. The primitive returns the list the receiver was previously on."
	| process myList |
	process := self stackTop.
	process = self activeProcess ifTrue:
		[self pop: 1 thenPush: objectMemory nilObject.
		 ^self transferTo: self wakeHighestPriority].
	myList := objectMemory fetchPointer: MyListIndex ofObject: process.
	"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
	but we can't easily so just do a quick check for nil which is the most common case."
	myList = objectMemory nilObject ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	"Alas in Spur we need a read barrier"
	(objectMemory isForwarded: myList) ifTrue:
		[myList := objectMemory followForwarded: myList.
		 objectMemory storePointer: MyListIndex ofObject: process withValue: myList].
	self removeProcess: process fromList: myList.
	self successful ifTrue:
		[objectMemory storePointer: MyListIndex ofObject: process withValue: objectMemory nilObject.
		 self pop: 1 thenPush: myList]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveTestAndSetOwnershipOfCriticalSection [
	"Attempt to test-and-set the ownership of the critical section.  If not owned,
	 set the owner to the current process and answer false. If owned by the
	 current process answer true.  If owned by some other process answer nil.
	 For simulation if there is an argument it is taken to be the effective activeProcess
	 (see Process>>effectiveProcess)."
	| criticalSection owningProcessIndex owningProcess activeProc |
	argumentCount > 0
		ifTrue:
			[criticalSection := self stackValue: 1.  "rcvr"
			 activeProc := self stackTop]
		ifFalse:
			[criticalSection := self stackTop.  "rcvr"
			 activeProc := self activeProcess].
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := objectMemory fetchPointer: owningProcessIndex ofObject: criticalSection.
	owningProcess = objectMemory nilObject ifTrue:
		[objectMemory storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: argumentCount + 1 thenPush: objectMemory falseObject].
	owningProcess = activeProc ifTrue:
		[^self pop: argumentCount + 1 thenPush: objectMemory trueObject].
	self pop: argumentCount + 1 thenPush: objectMemory nilObject
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveTestDisplayDepth [
	"Return true if the host OS does support the given display depth."
	| bitsPerPixel okay|
	bitsPerPixel := self stackIntegerValue: 0.
	self successful ifTrue: [okay := self ioHasDisplayDepth: bitsPerPixel].
	self successful ifTrue: [self pop: 2 thenPushBool: okay"Pop arg+rcvr"]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveTestShortenIndexableSize [
	"Given an object with indexable pointer fields, reduce the size of the indexable fields
	to the requested size. Answer the number of bytes freed, or zero if the object cannot
	be shortened."
	<option: #TestingPrimitives>
	<export: true>
	| array newSize bytesFreed |
	newSize := self stackIntegerValue: 0.
	array := self stackValue: 1.
	self pop: argumentCount + 1.
	bytesFreed := self shorten: array toIndexableSize: newSize.
	self pushInteger: bytesFreed
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveTimesTwoPower [
	"Multiply the receiver by the power of the argument."
	| rcvr result arg |
	<var: #rcvr type: #double>
	<var: #result type: #double>
	arg := self stackTop.
	(objectMemory isIntegerObject: arg) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	arg := objectMemory integerValueOf: arg.
	objectMemory bytesPerOop > 4 ifTrue:
		[| twiceMaxExponent | "clip arg to at most int range; ldexp's last arg is of type int"
		 twiceMaxExponent := 2 * (1 << self floatExponentBits).
	 	 arg < twiceMaxExponent negated
			ifTrue: [arg := twiceMaxExponent negated]
			ifFalse: [arg > twiceMaxExponent ifTrue:
						[arg := twiceMaxExponent]]].
	rcvr := objectMemory floatValueOf: (self stackValue: 1).
	result := self cCode: [self ld: rcvr exp: (self cCoerceSimple: arg to: #int)]
					inSmalltalk: [rcvr timesTwoPower: arg].
	self pop: 2 thenPushFloat: result
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveTruncated [
	"N.B. IMO we should be able to assume the receiver is a float because this primitive is specific to floats. eem 2/13/2017"
	| rcvr trunc |
	<var: #rcvr type: #double>
	<var: #trunc type: #double>
	rcvr := self stackFloatValue: 0.
	self successful ifTrue:
		[self cCode: [self mod: rcvr f: (self addressOf: trunc)]
			inSmalltalk: [trunc := rcvr = rcvr
									ifTrue: [rcvr truncated]
									ifFalse: [Float nan]].
		 (trunc between: objectMemory minSmallInteger asFloat and: objectMemory maxSmallInteger asFloat)
			ifTrue: [self stackTopPut: (objectMemory integerObjectOf: trunc asInteger)]
			ifFalse: [self primitiveFail]]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveUTCMicrosecondClock [
	"Return the value of the microsecond clock in UTC as an integer.
	 This is the number of microseconds since the Smalltalk epoch, 1901/1/1 12:00am.
	 The microsecond clock is at least 60 bits wide which means it'll get to around August
	 38435 before it wraps around.  Be sure to put it on your calendar.  This primitive
	 accesses the time as answered by the OS."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioUTCMicrosecondsNow)
]

{ #category : #'plugin primitives' }
InterpreterPrimitives >> primitiveUnloadModule [
	"Primitive. Unload the module with the given name."
	"Reloading of the module will happen *later* automatically, when a 
	 function from it is called. This is ensured by invalidating current sessionID."
	| moduleName |
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	moduleName := self stackTop.
	(objectMemory isBytes: moduleName) ifFalse:[^self primitiveFail].
	(self ioUnloadModule: (self oopForPointer: (objectMemory firstIndexableField: moduleName))
		OfLength: (objectMemory byteSizeOf: moduleName)) ifFalse:[^self primitiveFail].
	self flushExternalPrimitives.
	self forceInterruptCheck.
	self pop: 1 "pop moduleName; return receiver"
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveUpdateTimezone [
	"Update the VMs notion of the current timezone.  The VM sets its notion
	 of the timezone once at start-up.  If one wants the VM to keep its notion
	 up-to-date arrange to invoke this primitive periodically."
	self ioUpdateVMTimezone
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveUtcAndTimezoneOffset [
	"Answer an array with UTC microseconds since the Smalltalk epoch and the
	current seconds offset from GMT in the local time zone. Any pointer object
	 with two or more slots) may be supplied as a parameter."
	| resultArray |
	argumentCount > 0
		ifTrue:
			[argumentCount > 1 ifTrue: [^self primitiveFailFor: PrimErrBadNumArgs].
			 resultArray := self stackTop.
			 ((objectMemory isPointers: resultArray)
			  and: [(objectMemory lengthOf: resultArray) >= 2]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument]]
		ifFalse: [resultArray := objectMemory instantiateClass: objectMemory classArray indexableSize: 2].
	"N.B. No pushRemappableOop:/popRemappableOop in Cog because positive64BitIntegerFor: et al use
	 eeInstantiate... allocators which are guaranteed not to do a GC."
	objectMemory
		storePointerUnchecked: 1 ofObject: resultArray withValue: (objectMemory integerObjectOf: self ioLocalSecondsOffset);
		storePointer: 0 ofObject: resultArray withValue: (self positive64BitIntegerFor: self ioUTCMicroseconds).
	self pop: argumentCount + 1 thenPush: resultArray
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveUtcWithOffset [
	"Answer an array with UTC microseconds since the Posix epoch and the
	current seconds offset from GMT in the local time zone. An empty two
	element array (or any object with two or more slots) may be supplied
	as a parameter.
	This is a named (not numbered) primitive in the null module (ie the VM)"
	| epochDelta resultArray |
	<export: true>
	<var: #epochDelta declareC: 'static usqLong epochDelta = 2177452800000000ULL'>
	self cCode: '' inSmalltalk: [epochDelta := 2177452800000000].
	argumentCount > 0
		ifTrue:
			[argumentCount > 1 ifTrue: [^self primitiveFailFor: PrimErrBadNumArgs].
			 resultArray := self stackTop.
			 ((objectMemory isPointers: resultArray)
			  and: [(objectMemory lengthOf: resultArray) >= 2]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument]]
		ifFalse: [resultArray := objectMemory instantiateClass: objectMemory classArray indexableSize: 2].
	"N.B. No pushRemappableOop:/popRemappableOop in Cog because positive64BitIntegerFor: et al use
	 eeInstantiate... allocators which are guaranteed not to do a GC."
	objectMemory
		storePointerUnchecked: 1 ofObject: resultArray withValue: (objectMemory integerObjectOf: self ioLocalSecondsOffset);
		storePointer: 0 ofObject: resultArray withValue: (self positive64BitIntegerFor: self ioUTCMicroseconds - epochDelta).
	self pop: argumentCount + 1 thenPush: resultArray
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveV3IntegerAt [
	"Answer the 32bit signed integer contents of a words receiver"
	<inline: true>
	| index rcvr sz addr intValue result |
	<var: #intValue type: #int>
	index := self stackValue: 0.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	(objectMemory isWords: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := objectMemory integerValueOf: index.
	sz := objectMemory lengthOf: rcvr.  "number of fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	"4 = 32 bits / 8"
	addr := rcvr + objectMemory baseHeaderSize + (index - 1 * 4). "for zero indexing"
	intValue := objectMemory intAt: addr.
	result := self signed32BitIntegerFor: intValue.
	self pop: 2 thenPush: result
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveV3IntegerAtPut [
	"Assign an indexable variable of a words receiver with a 32 bit signed integer."
	| index rcvr sz addr value valueOop |
	<var: 'value' type: #int>
	valueOop := self stackValue: 0.
	index := self stackIntegerValue: 1.
	value := self signed32BitValueOf: valueOop.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	(objectMemory isWords: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	sz := objectMemory lengthOf: rcvr.  "number of fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	"4 = 32 bits / 8"
	addr := rcvr + objectMemory baseHeaderSize + (index - 1 * 4). "for zero indexing"
	value := objectMemory intAt: addr put: value.
	self pop: 3 thenPush: valueOop "pop all; return value"
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveV3StringReplace [
	"<array> primReplaceFrom: start to: stop with: replacement startingAt: repStart  
		<primitive: 105>"
	<inline: true>
	| array start stop repl replStart hdr arrayFmt totalLength arrayInstSize replFmt replInstSize srcIndex |
	array := self stackValue: 4.
	start := self stackIntegerValue: 3.
	stop := self stackIntegerValue: 2.
	repl := self stackValue: 1.
	replStart := self stackIntegerValue: 0.

	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument]. 
	(objectMemory isImmediate: repl) ifTrue: "can happen in LgInt copy"
		[^self primitiveFailFor: PrimErrBadArgument].
	(stop >= start and: [objectMemory isObjImmutable: array]) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].

	hdr := objectMemory baseHeader: array.
	arrayFmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: array baseHeader: hdr format: arrayFmt.
	arrayInstSize := objectMemory fixedFieldsOf: array format: arrayFmt length: totalLength.
	(start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= totalLength]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].

	hdr := objectMemory baseHeader: repl.
	replFmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: repl baseHeader: hdr format: replFmt.
	replInstSize := objectMemory fixedFieldsOf: repl format: replFmt length: totalLength.
	(replStart >= 1 and: [stop - start + replStart + replInstSize <= totalLength]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].

	"Array formats (without byteSize bits, if bytes array) must be the same"
	arrayFmt < objectMemory firstByteFormat
		ifTrue: [arrayFmt = replFmt ifFalse:
					[^self primitiveFailFor: PrimErrInappropriate]]
		ifFalse: [(arrayFmt bitAnd: objectMemory byteFormatMask) = (replFmt bitAnd: objectMemory byteFormatMask) ifFalse:
					[^self primitiveFailFor: PrimErrInappropriate]].

	srcIndex := replStart + replInstSize - 1.
	"- 1 for 0-based access"

	arrayFmt <= objectMemory lastPointerFormat
		ifTrue:
			[start + arrayInstSize - 1 to: stop + arrayInstSize - 1 do:
				[:i |
				objectMemory storePointer: i ofObject: array withValue: (objectMemory fetchPointer: srcIndex ofObject: repl).
				srcIndex := srcIndex + 1]]
		ifFalse:
			[arrayFmt < objectMemory firstByteFormat
				ifTrue: "32-bit-word type objects"
					[start + arrayInstSize - 1 to: stop + arrayInstSize - 1 do:
						[:i |
						objectMemory storeLong32: i ofObject: array withValue: (objectMemory fetchLong32: srcIndex ofObject: repl).
						srcIndex := srcIndex + 1]]
				ifFalse: "byte-type objects"
					[start + arrayInstSize - 1 to: stop + arrayInstSize - 1 do:
						[:i |
						objectMemory storeByte: i ofObject: array withValue: (objectMemory fetchByte: srcIndex ofObject: repl).
						srcIndex := srcIndex + 1]]].
	"We might consider comparing stop - start to some value here and using forceInterruptCheck"

	self pop: argumentCount "leave rcvr on stack"
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveVMCurrentThreadId [
	"Simulation only.  Fail."
	<doNotGenerate>
	self primitiveFail
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveVMPath [
	"Return a string containing the path name of VM's directory."

	| s sz |
	sz := self vmPathSize.
	s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: sz.
	self vmPathGet: (s + objectMemory baseHeaderSize) Length: sz.
	self pop: 1 thenPush: s.

]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveVMProfileInfoInto [
	"Primitive. Answer whether the profiler is running or not.
	 If the argument is an Array of suitable size fill it with the following information:
		1. the addresses of the first element of the VM histogram (the first address in the executable)
		2. the address following the last element (the last address in the executable, excluding dynamically linked libraries)
		3. the size of the VM histogram in bins (each bin is a 4 byte unsigned long)
		4. the size of the VM histogram in bins (each bin is a 4 byte unsigned long)"
	| info running exeStart exeLimit vmBins easBins |
	<var: #exeStart type: #'char *'>
	<var: #exeLimit type: #'char *'>
	<var: #vmBins type: #long>
	<var: #easBins type: #long>
	self success: argumentCount = 1.
	self successful ifTrue:
		[info := self stackObjectValue: 0].
	self successful ifTrue:
		[info ~= objectMemory nilObject ifTrue:
			[self assertClassOf: info is: (objectMemory splObj: ClassArray).
			 self success: (objectMemory numSlotsOf: info) >= 4]].
	self successful ifFalse:
		[^nil].
	
	self cCode: 'ioProfileStatus(&running,&exeStart,&exeLimit,0,&vmBins,0,&easBins)'
		inSmalltalk: [running := exeStart := exeLimit := vmBins := easBins := 0].
	info ~= objectMemory nilObject ifTrue:
		[objectMemory storePointerUnchecked: 0
			ofObject: info
			withValue: (objectMemory integerObjectOf: (self oopForPointer: exeStart)).
		objectMemory storePointerUnchecked: 1
			ofObject: info
			withValue: (objectMemory integerObjectOf: (self oopForPointer: exeLimit)).
		objectMemory storePointerUnchecked: 2
			ofObject: info
			withValue: (objectMemory integerObjectOf: vmBins).
		objectMemory storePointerUnchecked: 3
			ofObject: info
			withValue: (objectMemory integerObjectOf: easBins)].
	self pop: 2 thenPushBool: running
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveVMProfileSamplesInto [
	"Primitive.
	 0 args: Answer whether the VM Profiler is running or not.
	 1 arg:	Copy the sample data into the supplied argument, which must be a Bitmap
			of suitable size. Answer the number of samples copied into the buffer."
	| sampleBuffer running bufferSize numSamples |
	<var: #bufferSize type: #long>
	self ioNewProfile: (self addressOf: running put: [:v| running := v])
		Status: (self addressOf: bufferSize put: [:v| bufferSize := v]).
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPushBool: running].
	argumentCount = 1 ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	sampleBuffer := self stackValue: 0.
	((objectMemory isNonImmediate: sampleBuffer)
	 and: [(objectMemory isPureBitsNonImm: sampleBuffer)
	 and: [(objectMemory numBytesOf: sampleBuffer) >= (bufferSize * objectMemory wordSize)]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	numSamples := self ioNewProfileSamplesInto: (objectMemory firstFixedField: sampleBuffer).
	self pop: argumentCount + 1 thenPushInteger: numSamples
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveWait [
	| sema excessSignals activeProc |
	sema := self stackTop.  "rcvr"
	excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: sema.
	excessSignals > 0
		ifTrue:
			[self storeInteger: ExcessSignalsIndex ofObject: sema withValue: excessSignals - 1]
		ifFalse:
			[activeProc := self activeProcess.
			 self addLastLink: activeProc toList: sema.
			 self transferTo: self wakeHighestPriority]
]

{ #category : #'process primitives' }
InterpreterPrimitives >> primitiveYield [
	"Primitively do the equivalent of Process>yield, avoiding the overhead of a fork and a wait in the standard implementation."
	| scheduler activeProc priority processLists processList |
	scheduler := self schedulerPointer.
	activeProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: scheduler.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: scheduler.
	processList := objectMemory fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifFalse:
		[self addLastLink: activeProc toList: processList.
		 self transferTo: self wakeHighestPriority]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> quot: integerRcvr ient: integerArg [
	"See Number>>#quo:.  Rounds results towards zero."
	<inline: true>
	^integerRcvr > 0
		ifTrue:
			[integerArg > 0
				ifTrue: [integerRcvr // integerArg]
				ifFalse: [0 - (integerRcvr // (0 - integerArg))]]
		ifFalse:
			[integerArg > 0
				ifTrue: [0 - ((0 - integerRcvr) // integerArg)]
				ifFalse: [(0 - integerRcvr) // (0 - integerArg)]]
]

{ #category : #'string primitives' }
InterpreterPrimitives >> rawCompare: string1 length: strLength1 with: string2 length: strLength2 accessBlock: accessBlock [
	| c1 c2 min |
	<inline: true> "needs to be forced else slang does not inline it by default"
	min := strLength1 min: strLength2.
	0 to: min-1 do: 
		[:i | c1 := accessBlock value: string1 value: i.
			c2 := accessBlock value: string2 value: i.
			c1 = c2 ifFalse: [^c1 - c2]].
	^strLength1 - strLength2


	
	
	
]

{ #category : #'simulation support' }
InterpreterPrimitives >> sHEAFn [
	<doNotGenerate>
	^true
]

{ #category : #'primitive support' }
InterpreterPrimitives >> signalNoResume: aSemaphore [
	"Signal the given semaphore from within the interpreter.  Used to serialize callbacks."
	| empty |
	<api>
	<inline: false>
	empty := self isEmptyList: aSemaphore. 
	empty ifFalse:
		[self putToSleep: (self removeFirstLinkOfList: aSemaphore) yieldingIf: true].
	^empty
]

{ #category : #'primitive support' }
InterpreterPrimitives >> signed32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a SmallInteger or a four-byte LargeInteger."
	<returnTypeC: #int>
	
	objectMemory hasSixtyFourBitImmediates
		ifTrue:
			[(objectMemory isIntegerObject: oop) ifTrue:
				[| value64 |
				 value64 := objectMemory integerValueOf: oop.
				 (self cCode: [(self cCoerceSimple: value64 to: #int) ~= value64]
						inSmalltalk: [value64 >> 31 ~= 0 and: [value64 >> 31 ~= -1]]) ifTrue:
					[self primitiveFail. value64 := 0].
				 ^value64].
			self primitiveFail.
		 	^0]
		ifFalse:
			[(objectMemory isIntegerObject: oop) ifTrue:
				[^objectMemory integerValueOf: oop].
			^self noInlineSigned32BitValueGutsOf: oop]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> signed64BitValueOf: oop [
	"Convert the given object into an integer value.
	 The object may be either a positive SmallInteger or a eight-byte LargeInteger."
	| sz value negative ok magnitude |
	<inline: false>
	<returnTypeC: #sqLong>
	<var: #value type: #sqLong>
	<var: #magnitude type: #usqLong>
	(objectMemory isIntegerObject: oop) ifTrue:
		[^self cCoerce: (objectMemory integerValueOf: oop) to: #sqLong].

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[self primitiveFail.
		 ^0].

	ok := objectMemory isClassOfNonImm: oop
					equalTo: (objectMemory splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok
		ifTrue: [negative := false]
		ifFalse:
			[negative := true.
			 ok := objectMemory isClassOfNonImm: oop
							equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
			ok ifFalse:
				[self primitiveFail.
				 ^0]].
	sz := objectMemory numBytesOfBytes: oop.
	sz > (self sizeof: #sqLong) ifTrue:
		[self primitiveFail.
		 ^0].

	"self cppIf: SPURVM
		ifTrue:
			[""Memory is 8 byte aligned in Spur and oversized bytes are set to zero, so we can safely fetch 8 bytes""
			magnitude := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
		ifFalse:
			["sz > 4
				ifTrue: [magnitude := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
				ifFalse: [magnitude := self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int']"]".

	(negative
		ifTrue: [magnitude > 16r8000000000000000]
		ifFalse: [magnitude >= 16r8000000000000000])
			ifTrue: [self primitiveFail.
				^0].
	negative
		ifTrue: [value := 0 - magnitude]
		ifFalse: [value := magnitude].
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> signedMachineIntegerValueOf: oop [
	"Answer a signed value of an integer up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargeInteger of size <= word size."
	<returnTypeC: #'sqIntptr_t'>
	| negative ok bs value limit magnitude |
	<var: #value type: #sqInt>
	<var: #magnitude type: #'usqIntptr_t'>
	<var: #limit type: #'usqIntptr_t'>
	(objectMemory isIntegerObject: oop) ifTrue:
		[^objectMemory integerValueOf: oop].

	(objectMemory isNonIntegerImmediate: oop) ifTrue:
		[^self primitiveFail].

	ok := objectMemory isClassOfNonImm: oop
					equalTo: (objectMemory splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok
		ifTrue: [negative := false]
		ifFalse:
			[negative := true.
			 ok := objectMemory isClassOfNonImm: oop
							equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
			ok ifFalse: [^self primitiveFail]].
	bs := objectMemory numBytesOf: oop.
	bs > (self sizeof: #'usqIntptr_t') ifTrue:
		[^self primitiveFail].

	"self cppIf: SPURVM
		ifTrue:
			[""Memory is 8 byte aligned in Spur and oversized bytes are set to zero, so we can safely fetch 8 bytes""
			magnitude := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
		ifFalse:
			["((self sizeof: #'sqIntptr_t') = 8
			and: [bs > 4])
				ifTrue:
					[magnitude := objectMemory byteSwapped64IfBigEndian: (objectMemory fetchLong64: 0 ofObject: oop)]
				ifFalse:
					[magnitude := self cCoerceSimple: (objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: oop)) to: #'unsigned int']"]".

	limit := 1 asUnsignedIntegerPtr << ((self sizeof: #'sqIntptr_t') * 8 - 1).
	(negative
		ifTrue: [magnitude > limit]
		ifFalse: [magnitude >= limit])
			ifTrue: [self primitiveFail.
				^0].
	negative
		ifTrue: [value := 0 - magnitude]
		ifFalse: [value := magnitude].
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> sizeFieldOfAlien: alienObj [
	"Answer the first field of alienObj which is assumed to be an Alien of at least 8 bytes"
	<inline: true>
	^objectMemory longAt: alienObj + objectMemory baseHeaderSize
]

{ #category : #'primitive support' }
InterpreterPrimitives >> sizeOfAlienData: oop [
	"Answer the start of the Alien's data or fail if oop is not an Alien."
	<api>
	<returnTypeC: #usqInt>
	| size |
	(self is: oop KindOfClass: (objectMemory splObj: ClassAlien)) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^0].
	size := self sizeFieldOfAlien: oop.
	^size abs
]

{ #category : #'primitive support' }
InterpreterPrimitives >> startOfAlienData: oop [
	"Answer the start of the Alien's data or fail if oop is not an Alien."
	<api>
	<returnTypeC: #'void *'>
	(self is: oop KindOfClass: (objectMemory splObj: ClassAlien)) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^0].
	^self cCoerceSimple: ((self isDirectAlien: oop)
						 	ifTrue: [oop + objectMemory baseHeaderSize + objectMemory bytesPerOop]
							ifFalse: [objectMemory longAt: oop + objectMemory baseHeaderSize + objectMemory bytesPerOop])
			to: #'void *'
]

{ #category : #'primitive support' }
InterpreterPrimitives >> success: successBoolean [
	"Set the state of the primitive failure code/success flag, iff successBoolean
	 is false. If primFailCode is non-zero a primitive has failed.  If primFailCode
	 is greater than one then its value indicates the reason for failure."

	"Use returnTypeC: #sqInt because that's the way it is defined in sq.h.
	 Use no explicit return so that Slang doesn't fail an inlining type-check when
	 a primitive with return type void uses ^self success: false to exit."
	<returnTypeC: #sqInt>
	<inline: true>
	successBoolean ifFalse:
		["Don't overwrite an error code that has already been set."
		 self successful ifTrue:
			[primFailCode := 1]]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> successful [
	"Answer the state of the primitive failure code/success flag.  If
	 primFailCode is non-zero a primitive has failed.  If primFailCode
	 is greater than one then its value indicates the reason for failure."
	<inline: true>
	
	"In C, non-zero is true, so avoid computation by using not the C version."
	^self cCode: [primFailCode not] inSmalltalk: [primFailCode = 0]
]
