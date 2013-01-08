"
InterpreterPrimitives implements most of the VM's core primitives.  It is the root of the interpreter hierarchy so as to share the core primitives amongst the varioius interpreters.

Instance Variables
	argumentCount:	<Integer>
	messageSelector:	<Integer>
	newMethod:		<Integer>
	nextProfileTick:		<Integer>
	objectMemory:		<ObjectMemory> (simulation only)
	preemptionYields:	<Boolean>
	primFailCode:		<Integer>
	profileMethod:		<Integer>
	profileProcess:		<Integer>
	profileSemaphore:	<Integer>

argumentCount
	- the number of arguments of the current message

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
	- primtiive success/failure flag, 0 for success, otherwise the reason code for failure

profileMethod
	- the oop of the method at the time nextProfileTick was reached

profileProcess
	- the oop of the activeProcess at the time nextProfileTick was reached

profileSemaphore
	- the oop of the semaphore to signal when nextProfileTick is reached

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
		'profileMethod',
		'profileProcess',
		'profileSemaphore',
		'nextProfileTick',
		'preemptionYields'
	],
	#classVars : [
		'CrossedX',
		'EndOfRun',
		'MillisecondClockMask'
	],
	#pools : [
		'VMBasicConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMSqueakV3BytecodeConstants',
		'VMSqueakV3ObjectRepresentationConstants',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #'primitive support' }
InterpreterPrimitives >> cStringOrNullFor: oop [
	"Answer either a malloced string with the null-terminated contents of oop if oop is a string,
	 or the null pointer if oop is nil, or fail.  It is the client's responsibility to free the string later."
	<api>
	<returnTypeC: #'char *'>
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
	self mem: cString cp: (objectMemory firstIndexableField: oop) y: len.
	cString at: len put: 0.
	^cString
]

{ #category : #'primitive support' }
InterpreterPrimitives >> failed [
	<api>
	"In C, non-zero is true, so avoid computation by simply answering primFailCode in the C version."
	^self cCode: [primFailCode] inSmalltalk: [primFailCode ~= 0]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> initPrimCall [
	"Set the failure code/success flag in preparation for calling a primitve.
	 If primFailCode is non-zero a primitive has failed.  If primFailCode is
	 greater than one then its value indicates the reason for failure."
	<inline: true>
	primFailCode := 0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isDirectAlien: oop [
	^(self sizeFieldOfAlien: oop) > 0
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
InterpreterPrimitives >> isInstanceOfClassCharacter: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassCharacter) is expanded in-place
	 and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassCharacter) 
		compactClassIndex: 0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isInstanceOfClassFloat: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassFloat) is expanded in-place and is
	 _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassFloat) 
		compactClassIndex: ClassFloatCompactIndex
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isInstanceOfClassLargeNegativeInteger: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassLargeNegativeInteger) is expanded
	 in-place and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassLargeNegativeInteger) 
		compactClassIndex: ClassLargeNegativeIntegerCompactIndex
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isInstanceOfClassLargePositiveInteger: oop [
	<inline: true>
	"N.B.  Because Slang always inlines is:instanceOf:compactClassIndex:
	 (because is:instanceOf:compactClassIndex: has an inline: pragma) the
	 phrase (objectMemory splObj: ClassLargePositiveInteger) is expanded
	 in-place and is _not_ evaluated if oop has a non-zero CompactClassIndex."
	^objectMemory
		is: oop
		instanceOf: (objectMemory splObj: ClassLargePositiveInteger) 
		compactClassIndex: ClassLargePositiveIntegerCompactIndex
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isNegativeIntegerValueOf: oop [
	"Answer true if integer object is negative.
	Fail if object pointed by oop i not an integer."
	| ok smallInt |

	(objectMemory isIntegerObject: oop)
		ifTrue:
			[smallInt := objectMemory integerValueOf: oop.
			^smallInt < 0].

	ok := objectMemory isClassOfNonImm: oop
					equalTo: (objectMemory splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok ifTrue: [^false].
		
	ok := objectMemory isClassOfNonImm: oop
							equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
	ok ifTrue: [^true].
	self primitiveFail.
	^false
]

{ #category : #'primitive support' }
InterpreterPrimitives >> isPointerAlien: oop [
	^(self sizeFieldOfAlien: oop) = 0
]

{ #category : #'primitive support' }
InterpreterPrimitives >> magnitude64BitIntegerFor: magnitude neg: isNegative [
	"Return a Large Integer object for the given integer magnitude and sign"
	| newLargeInteger largeClass intValue highWord sz isSmall smallVal |
	<var: 'magnitude' type: #usqLong>
	<var: 'highWord' type: #usqInt>

	isSmall := isNegative
				ifTrue: [magnitude <= 16r40000000]
				ifFalse: [magnitude < 16r40000000].
	isSmall ifTrue:
		[smallVal := self cCoerceSimple: magnitude to: #sqInt.
		isNegative	ifTrue: [smallVal := 0 - smallVal].
		^objectMemory integerObjectOf: smallVal].
	largeClass := isNegative
					ifTrue: [objectMemory classLargeNegativeInteger]
					ifFalse: [objectMemory classLargePositiveInteger].
	highWord := magnitude >> 32.
	highWord = 0 
		ifTrue: [sz := 4] 
		ifFalse:
			[sz := 5.
			(highWord := highWord >> 8) = 0 ifFalse: [sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse: [sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse: [sz := sz + 1]].
	newLargeInteger := objectMemory instantiateClass: largeClass indexableSize:  sz.
	0 to: sz-1 do: [:i |
		intValue := (magnitude >> (i * 8)) bitAnd: 255.
		objectMemory storeByte: i ofObject: newLargeInteger withValue: intValue].
	^newLargeInteger
]

{ #category : #'primitive support' }
InterpreterPrimitives >> magnitude64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or a eight-byte LargeInteger."
	| sz value ok smallIntValue |
	<returnTypeC: #usqLong>
	<var: #value type: #usqLong>

	(objectMemory isIntegerObject: oop) ifTrue:
		[smallIntValue := (objectMemory integerValueOf: oop).
		smallIntValue < 0 ifTrue: [smallIntValue := 0 - smallIntValue].
		^self cCoerce: smallIntValue to: #usqLong].

	ok := objectMemory isClassOfNonImm: oop
					equalTo: (objectMemory splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok
		ifFalse:
			[ok := objectMemory isClassOfNonImm: oop
							equalTo: (objectMemory splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
			ok ifFalse: [^self primitiveFail]].
	sz := objectMemory lengthOf: oop.
	sz > (self sizeof: #sqLong) ifTrue:
		[^self primitiveFail].

	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (objectMemory fetchByte: i ofObject: oop) to: #sqLong) <<  (i*8))].
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> positive32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or a four-byte LargePositiveInteger."

	| value ok |
	(objectMemory isIntegerObject: oop) ifTrue:
		[value := objectMemory integerValueOf: oop.
		value < 0 ifTrue: [self primitiveFail. value := 0].
		^value].

	ok := objectMemory isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	(ok and: [(objectMemory lengthOf: oop) = 4]) ifFalse:
		[self primitiveFail.
		 ^0].
	^(objectMemory fetchByte: 0 ofObject: oop)
	+ ((objectMemory fetchByte: 1 ofObject: oop) <<  8)
	+ ((objectMemory fetchByte: 2 ofObject: oop) << 16)
	+ ((objectMemory fetchByte: 3 ofObject: oop) << 24)
]

{ #category : #'primitive support' }
InterpreterPrimitives >> positive64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or an eight-byte LargePositiveInteger."

	<returnTypeC: #sqLong>
	| sz value ok |
	<var: #value type: #sqLong>
	(objectMemory isIntegerObject: oop) ifTrue:
		[value := objectMemory integerValueOf: oop.
		 value < 0 ifTrue: [^self primitiveFail].
		 ^value].

	ok := objectMemory
			isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	(ok and: [(sz := objectMemory lengthOf: oop) <= (self sizeof: #sqLong)]) ifFalse:
		[^self primitiveFail].

	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (objectMemory fetchByte: i ofObject: oop) to: #sqLong) <<  (i*8))].
	^value
]

{ #category : #'primitive support' }
InterpreterPrimitives >> positiveMachineIntegerValueOf: oop [
	"Answer a value of an integer in address range, i.e up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargePositiveInteger of size <= word size."
	<returnTypeC: #'unsigned long'>
	| value bs ok |
	(objectMemory isIntegerObject: oop) ifTrue:
		[value := objectMemory integerValueOf: oop.
		 value < 0 ifTrue: [^self primitiveFail].
		^value].

	ok := objectMemory
			isClassOfNonImm: oop
			equalTo: (objectMemory splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	(ok and: [(bs := objectMemory lengthOf: oop) <= (self sizeof: #'unsigned long')]) ifFalse:
		[^self primitiveFail].

	((self sizeof: #'unsigned long') = 8
	and: [bs > 4]) ifTrue:
		[^  (objectMemory fetchByte: 0 ofObject: oop)
		 + ((objectMemory fetchByte: 1 ofObject: oop) <<  8)
		 + ((objectMemory fetchByte: 2 ofObject: oop) << 16)
		 + ((objectMemory fetchByte: 3 ofObject: oop) << 24)
		 + ((objectMemory fetchByte: 4 ofObject: oop) << 32)
		 + ((objectMemory fetchByte: 5 ofObject: oop) << 40)
		 + ((objectMemory fetchByte: 6 ofObject: oop) << 48)
		 + ((objectMemory fetchByte: 7 ofObject: oop) << 56)].

	^  (objectMemory fetchByte: 0 ofObject: oop)
	+ ((objectMemory fetchByte: 1 ofObject: oop) <<  8)
	+ ((objectMemory fetchByte: 2 ofObject: oop) << 16)
	+ ((objectMemory fetchByte: 3 ofObject: oop) << 24)
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

	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	err := objectMemory changeClassOf: arg to: rcvr.
	err = 0
		ifTrue: ["Flush at cache because rcvr's class has changed."
				self flushAtCache.
				self pop: self methodArgumentCount]
		ifFalse: [self primitiveFailFor: err].
	^nil
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveArctan [

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'atan(rcvr)' inSmalltalk: [rcvr arcTan])]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveArrayBecome [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := objectMemory become: rcvr with: arg twoWay: true copyHash: true.
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
	"Similar to primitiveArrayBecomeOneWay but accepts a third argument whether to copy
	the receiver's identity hash over the argument's identity hash."

	| copyHashFlag arg rcvr ec |
	copyHashFlag := self booleanValueOf: (self stackTop).
	arg := self stackValue: 1.
	rcvr := self stackValue: 2.
	ec := objectMemory become: rcvr with: arg twoWay: false copyHash: copyHashFlag.
	ec = PrimNoErr
		ifTrue: [self pop: 2]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveAsFloat [
	| arg |
	arg := self popInteger.
	self successful
		ifTrue: [ self pushFloat: (self cCode: '((double) arg)' inSmalltalk: [arg asFloat]) ]
		ifFalse: [ self unPop: 1 ]
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveAt [

	self commonAt: false.
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveAtPut [

	self commonAtPut: false.
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveBeCursor [
	"Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk."

	| cursorObj maskBitsIndex maskObj bitsObj extentX extentY depth offsetObj offsetX offsetY cursorBitsIndex ourCursor |

self flag: #Dan.  "This is disabled until we convert bitmaps appropriately"
BytesPerWord = 8 ifTrue: [self pop: argumentCount. ^nil].

	argumentCount = 0 ifTrue: [
		cursorObj := self stackTop.
		maskBitsIndex := nil].
	argumentCount = 1 ifTrue: [
		cursorObj := self stackValue: 1.
		maskObj := self stackTop].
	self success: (argumentCount < 2).

	self success: ((objectMemory isPointers: cursorObj) and: [(objectMemory lengthOf: cursorObj) >= 5]).
	self successful ifTrue: [
		bitsObj := objectMemory fetchPointer: 0 ofObject: cursorObj.
		extentX := self fetchInteger: 1 ofObject: cursorObj.
		extentY := self fetchInteger: 2 ofObject: cursorObj.
		depth := self fetchInteger: 3 ofObject: cursorObj.
		offsetObj := objectMemory fetchPointer: 4 ofObject: cursorObj].
		self success: ((objectMemory isPointers: offsetObj) and: [(objectMemory lengthOf: offsetObj) >= 2]).

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
				cursorBitsIndex := bitsObj + BaseHeaderSize.
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
				cursorBitsIndex := bitsObj + BaseHeaderSize.
				self cCode: '' inSmalltalk:
					[ourCursor := Cursor
						extent: extentX @ extentY
						fromArray: ((1 to: 16) collect: [:i |
							((objectMemory fetchLong32: i-1 ofObject: bitsObj) >> (BytesPerWord*8 - 16)) bitAnd: 16rFFFF])
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
			maskBitsIndex := bitsObj + BaseHeaderSize]].

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
	"Record the system Display object in the specialObjectsTable."
	| rcvr |
	rcvr := self stackTop.
	self success: ((objectMemory isPointers: rcvr) and: [(objectMemory lengthOf: rcvr) >= 4]).
	self successful ifTrue: [objectMemory splObj: TheDisplay put: rcvr]
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveBeep [
"make the basic beep noise"
	self ioBeep.
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveBehaviorHash [
	| hashOrError |
	self assert: (objectMemory isIntegerObject: self stackTop) not.
	hashOrError := objectMemory ensureBehaviorHash: self stackTop.
	hashOrError >= 0
		ifTrue: [self pop: 1 thenPushInteger: hashOrError]
		ifFalse: [self primitiveFailFor: hashOrError negated]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitAnd [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitAnd: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitAndLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitAnd: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitOr [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitOr: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitOrLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitOr: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveBitShift [ 
	| integerReceiver integerArgument shifted |
	integerArgument := self popInteger.
	integerReceiver := self popPos32BitInteger.
	self successful ifTrue: [
		integerArgument >= 0 ifTrue: [
			"Left shift -- must fail if we lose bits beyond 32"
			self success: integerArgument <= 31.
			shifted := integerReceiver << integerArgument.
			self success: (shifted >> integerArgument) = integerReceiver.
		] ifFalse: [
			"Right shift -- OK to lose bits"
			self success: integerArgument >= -31.
			shifted := integerReceiver >> (0 - integerArgument).
		].
	].
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor: shifted)]
		ifFalse: [self unPop: 2]
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
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitXor: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
InterpreterPrimitives >> primitiveBitXorLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitXor: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveBytesLeft [
	"Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection."
	| aBool |
	self methodArgumentCount = 0
		ifTrue: ["old behavior - just return the size of free memory"
			^self pop: 1 thenPushInteger: objectMemory freeSize].
	self methodArgumentCount = 1
		ifTrue: ["new behaviour -including or excluding swap space depending on aBool"
			aBool := self booleanValueOf: self stackTop.
			self successful ifTrue:
				[^self pop: 2 thenPushInteger: (objectMemory bytesLeft: aBool)]].
	^ self primitiveFail
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
	argClass := objectMemory fetchClassOfNonInt: arg.
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
	self pop: argumentCount+1 thenPush: (objectMemory fetchClassOf: instance)
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
		ifTrue: [s := self stackTop.
			(objectMemory isBytes: s) ifFalse: [^ self primitiveFail].
			self successful
				ifTrue: [sz := self stSizeOf: s.
					self clipboardWrite: sz From: s + BaseHeaderSize At: 0.
					self pop: 1]]
		ifFalse: [sz := self clipboardSize.
			(objectMemory sufficientSpaceToAllocate: sz) ifFalse:[^self primitiveFail].
			s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: sz.
			self clipboardRead: sz Into: s + BaseHeaderSize At: 0.
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

	| newCopy |
	newCopy := objectMemory clone: (self stackTop).
	newCopy = 0
		ifTrue:["not enough memory most likely" ^self primitiveFail].
	self pop: 1 thenPush: newCopy.
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
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	"Note we use activateNewMethod, not executeNewMethod, to avoid
	 quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: true
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveClosureValueNoContextSwitch [
	"An exact clone of primitiveClosureValue except that this version will not
	 check for interrupts on stack overflow.  It may invoke the garbage collector
	 but will not switch processes.  See checkForInterruptsMayContextSwitch:"
	| blockClosure numArgs closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	"Note we use activateNewMethod, not executeNewMethod, to avoid
	 quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: false
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveClosureValueWithArgs [
	| argumentArray arraySize blockClosure numArgs closureMethod index outerContext |
	argumentArray := self stackTop.
	(objectMemory isArray: argumentArray) ifFalse:
		[^self primitiveFail].

	"Check for enough space in thisContext to push all args"
	arraySize := objectMemory fetchWordLengthOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFail].

	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	arraySize = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(objectMemory isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self popStack.

	"Copy the arguments to the stack, and activate"
	index := 1.
	[index <= numArgs]
		whileTrue:
		[self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].

	"Note we use activateNewMethod, not executeNewMethod, to avoid
	 quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: true
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveCompareBytes [
	"Primitive. Compare two byte-indexed objects for equality"
	| arg1 arg2 len1 len2 |
	<export: true>
	argumentCount = 1 ifFalse:[^self primitiveFail].
	arg1 := self stackValue: 1.
	arg2 := self stackValue: 0.
	((objectMemory isBytes: arg1) and:[objectMemory isBytes: arg2]) 
		ifFalse:[^self primitiveFail].
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

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveConstantFill [
	"Fill the receiver, which must be an indexable bytes or words 
	objects, with the given integer value."
	| fillValue rcvr rcvrIsBytes end i |
	<var: #end type: #usqInt>
	<var: #i type: #usqInt>
	fillValue := self positive32BitValueOf: self stackTop.
	rcvr := self stackValue: 1.
	self success: (objectMemory isWordsOrBytes: rcvr).
	rcvrIsBytes := objectMemory isBytes: rcvr.
	rcvrIsBytes ifTrue: [self success: (fillValue >= 0 and: [fillValue <= 255])].
	self successful ifTrue:
		[end := rcvr + (objectMemory sizeBitsOf: rcvr).
		i := rcvr + BaseHeaderSize.
		rcvrIsBytes
			ifTrue: [[i < end] whileTrue:
						[objectMemory byteAt: i put: fillValue.
						i := i + 1]]
			ifFalse: [[i < end] whileTrue:
						[objectMemory long32At: i put: fillValue.
						i := i + 4]].
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
	numSamples := self cCode: 'ioControlNewProfile(onOffBar,bufferSize)'.
	self pop: 3 thenPushInteger: numSamples
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveCopyObject [
	"Primitive. Copy the state of the receiver from the argument. 
		Fail if receiver and argument are of a different class. 
		Fail if the receiver or argument are non-pointer objects.
		Fail if receiver and argument have different lengths (for indexable objects).
	"
	| rcvr arg length |
	self methodArgumentCount = 1 ifFalse:
		[^self primitiveFail].
	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	self failed ifTrue:[^nil].
	(objectMemory isPointers: rcvr) ifFalse:
		[^self primitiveFail].
	(objectMemory fetchClassOfNonInt: rcvr) = (objectMemory fetchClassOfNonInt: arg) ifFalse:
		[^self primitiveFail].
	length := objectMemory lengthOf: rcvr.
	length = (objectMemory lengthOf: arg) ifFalse:
		[^self primitiveFail].
	
	"Now copy the elements"
	0 to: length-1 do:[:i|
		objectMemory storePointer: i ofObject: rcvr withValue: (objectMemory fetchPointer: i ofObject: arg)].

	"Note: The above could be faster for young receivers but I don't think it'll matter"
	self pop: 1. "pop arg; answer receiver"

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
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := self compare31or32Bits: integerReceiver equal: integerArgument.
	self checkBooleanResult: result
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
	"Computes E raised to the receiver power."

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'exp(rcvr)' inSmalltalk: [rcvr exp])]
		ifFalse: [self unPop: 1]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveExponent [
	"Exponent part of this float."

	| rcvr frac pwr |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #pwr type: #int>
	rcvr := self popFloat.
	self successful
		ifTrue: [  "rcvr = frac * 2^pwr, where frac is in [0.5..1.0)"
			self cCode: 'frac = frexp(rcvr, &pwr)'
					inSmalltalk: [pwr := rcvr exponent].
			self pushInteger: pwr - 1]
		ifFalse: [self unPop: 1]
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
InterpreterPrimitives >> primitiveFailureCode [
	<api>
	^primFailCode
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFindHandlerContext [
	"Primitive. Search up the context stack for the next method context marked
	 for exception handling starting at the receiver. Return nil if none found"
	| handlerOrNilOrZero |
	self externalWriteBackHeadFramePointers.
	handlerOrNilOrZero := self
							findMethodWithPrimitive: 199
							FromContext: self stackTop
							UpToContext: objectMemory nilObject.
	handlerOrNilOrZero = 0 ifTrue:
		[handlerOrNilOrZero := objectMemory nilObject].
	self pop: 1 thenPush: handlerOrNilOrZero
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveFindNextUnwindContext [
	"Primitive. Search up the context stack for the next method context marked for unwind
	 handling from the receiver up to but not including the argument. Return nil if none found."
	| stopContext calleeContext handlerOrNilOrZero |
	<var: #theFP type: #'char *'>
	stopContext := self stackTop.
	calleeContext := self stackValue: 1.
	(stopContext = objectMemory nilObject or: [self isContext: stopContext]) ifFalse:
		[^self primitiveFail].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: calleeContext)
		ifTrue:
			[| theFP |
			 theFP := self frameOfMarriedContext: calleeContext.
			 (self isBaseFrame: theFP)
				ifTrue:
					[handlerOrNilOrZero := self findMethodWithPrimitive: 198
												FromContext: (self frameCallerContext: theFP)
												UpToContext: stopContext]
				ifFalse:
					[handlerOrNilOrZero :=  self findMethodWithPrimitive: 198
												FromFP: (self frameCallerFP: theFP)
												UpToContext: stopContext]]
		ifFalse:
			[| startContext |
			 startContext := objectMemory fetchPointer: SenderIndex ofObject: calleeContext.
			 (self isContext: startContext)
				ifTrue:
					[handlerOrNilOrZero := self findMethodWithPrimitive: 198
												FromContext: startContext
												UpToContext: stopContext]
				ifFalse:
					[handlerOrNilOrZero := 0]].
	handlerOrNilOrZero = 0 ifTrue:
		[handlerOrNilOrZero := objectMemory nilObject].
	self pop: 2 thenPush: handlerOrNilOrZero
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
	| rcvr index result |
	<var: #result type: #usqInt>
	self initPrimCall.
	rcvr := self stackValue: 1.
	index := self stackTop.
	index = ConstOne ifTrue:
		[result := self positive32BitIntegerFor:
					(objectMemory fetchLong32: (VMBIGENDIAN ifTrue: [0] ifFalse: [1])
						ofObject: rcvr).
		^self pop: 2 thenPush: result].
	index = ConstTwo ifTrue:
		[result := self positive32BitIntegerFor:
					(objectMemory fetchLong32: (VMBIGENDIAN ifTrue: [1] ifFalse: [0])
						ofObject: rcvr).
		^self pop: 2 thenPush: result].
	self primitiveFailFor: ((objectMemory isIntegerObject: index)
							ifTrue: [PrimErrBadIndex]
							ifFalse: [PrimErrBadArgument])
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveFloatAtPut [
	"Provide platform-independent access to 32-bit words comprising
	 a Float.  Map index 1 onto the most significant word and index 2
	 onto the least significant word."
	| rcvr index oopToStore valueToStore |
	<var: #result type: #usqInt>
	self initPrimCall.
	oopToStore := self stackTop.
	valueToStore := self positive32BitValueOf: oopToStore.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	index := self stackValue: 1.
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

	self flushMethodCache.
	self flushAtCache
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
	objectMemory forceTenureFlag: 1
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveFormPrint [
	"On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer."

	| landscapeFlag vScale hScale rcvr bitsArray w h
	 depth pixelsPerWord wordsPerLine bitsArraySize ok |

	<var: #vScale type: 'double '>
	<var: #hScale type: 'double '>
	landscapeFlag := self booleanValueOf: self stackTop.
	vScale := self floatValueOf: (self stackValue: 1).
	hScale := self floatValueOf: (self stackValue: 2).
	rcvr := self stackValue: 3.
	(rcvr isIntegerObject: rcvr) ifTrue: [self success: false].
	self successful ifTrue: [
		((objectMemory  isPointers: rcvr) and: [(objectMemory lengthOf: rcvr) >= 4])
			ifFalse: [self success: false]].
	self successful ifTrue: [
		bitsArray := objectMemory fetchPointer: 0 ofObject: rcvr.
		w := self fetchInteger: 1 ofObject: rcvr.
		h := self fetchInteger: 2 ofObject: rcvr.
		depth := self fetchInteger: 3 ofObject: rcvr.
		(w > 0 and: [h > 0]) ifFalse: [self success: false].
		pixelsPerWord := 32 // depth.
		wordsPerLine := (w + (pixelsPerWord - 1)) // pixelsPerWord.
		((rcvr isIntegerObject: rcvr) not and: [objectMemory isWordsOrBytes: bitsArray])
			ifTrue: [
				bitsArraySize := objectMemory byteLengthOf: bitsArray.
				self success: (bitsArraySize = (wordsPerLine * h * 4))]
			ifFalse: [self success: false]].	
	self successful ifTrue: [
		BytesPerWord = 8
			ifTrue: [ok := self cCode: 'ioFormPrint(bitsArray + 8, w, h, depth, hScale, vScale, landscapeFlag)']
			ifFalse: [ok := self cCode: 'ioFormPrint(bitsArray + 4, w, h, depth, hScale, vScale, landscapeFlag)'].
		self success: ok].
	self successful ifTrue: [
		self pop: 3].  "pop hScale, vScale, and landscapeFlag; leave rcvr on stack"
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveFractionalPart [
	| rcvr frac trunc |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #trunc type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self cCode: 'frac = modf(rcvr, &trunc)' inSmalltalk: [frac := rcvr fractionPart].
				self pushFloat: frac]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveFullGC [
	"Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported)."

	objectMemory fullGCLock > 0 ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	self externalWriteBackHeadFramePointers.
	objectMemory incrementalGC.  "maximimize space for forwarding table"
	objectMemory fullGC.
	self pop: 1 thenPushInteger: (objectMemory bytesLeft: true).
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
				Into: s + BaseHeaderSize
				Length: sz.
			self pop: 2 thenPush: s]
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
	self pop: self methodArgumentCount+1.
	self push: stringOop.
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveGetNextEvent [
	"Primitive. Return the next input event from the VM event queue."
	| evtBuf arg value |
	<var: #evtBuf declareC:'int evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 }'>
	self cCode:'' inSmalltalk:[evtBuf := CArrayAccessor on: (IntegerArray new: 8)].
	arg := self stackTop.
	((objectMemory isArray: arg) and:[(objectMemory slotSizeOf: arg) = 8])  ifFalse:[^self primitiveFail].

	self ioGetNextEvent: (self cCoerce: evtBuf to: 'sqInputEvent*').
	self successful ifFalse:[^nil].

	"Event type"
	self storeInteger: 0 ofObject: arg withValue: (evtBuf at: 0).
	self successful ifFalse:[^nil].

	"Event time stamp"
	self storeInteger: 1 ofObject: arg withValue: ((evtBuf at: 1) bitAnd: MillisecondClockMask).
	self successful ifFalse:[^nil].

	"Event arguments"
	2 to: 7 do:[:i|
		value := evtBuf at: i.
		(objectMemory isIntegerValue: value)
			ifTrue:[self storeInteger: i ofObject: arg withValue: value]
			ifFalse:[value := self positive32BitIntegerFor: value.
				objectMemory storePointer: i ofObject: arg withValue: value]].

	self successful ifFalse:[^nil].
	self pop: 1
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
	self pop: self methodArgumentCount+1.
	self push: labelOop.
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

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveGreaterOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver >= integerArgument
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
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver > integerArgument
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
	self pop: argumentCount + 1 thenPushBool: thisObject = otherObject
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveIdentityHash [
	| thisReceiver |
	thisReceiver := self stackTop.
	(objectMemory isIntegerObject: thisReceiver)
		ifTrue: [self primitiveFail]
		ifFalse: [self pop:1 thenPushInteger: (objectMemory hashBitsOf: thisReceiver)]
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
		sCRIfn ~= 0 ifTrue:[okToRename := self cCode:' ((sqInt (*)(void))sCRIfn)()'.
			okToRename ifFalse:[^self primitiveFail]].
		s := self stackTop.
		self assertClassOf: s is: (objectMemory splObj: ClassByteString).
		self successful ifTrue: [
			sz := self stSizeOf: s.
			self imageNamePut: (s + BaseHeaderSize) Length: sz.
			self pop: 1.  "pop s, leave rcvr on stack"
		].
	] ifFalse: [
		sz := self imageNameSize.
		s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: sz.
		self imageNameGet: (s + BaseHeaderSize) Length: sz.
		self pop: 1.  "rcvr"
		self push: s.
	]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available.
	 (Note: more space may be made available by doing a full garbage collection."

	self externalWriteBackHeadFramePointers.
	objectMemory incrementalGC.
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
	arg := self popStack.
	(objectMemory fetchClassOf: arg) = (objectMemory splObj: ClassSemaphore) ifFalse:
		[arg := objectMemory nilObject].
	objectMemory splObj: TheInputSemaphore put: arg
]

{ #category : #'I/O primitives' }
InterpreterPrimitives >> primitiveInputWord [
	"Return an integer indicating the reason for the most recent input interrupt."

	self pop: 1 thenPushInteger: 0.	"noop for now"
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index := self stackIntegerValue: 0.
	rcvr := self stackValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(fmt = 3
	 and: [objectMemory isContextHeader: hdr])
		ifTrue: [value := self externalInstVar: index - 1 ofContext: rcvr]
		ifFalse: [value := self subscript: rcvr with: index format: fmt].
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue := self stackTop.
	index := self stackIntegerValue: 1.
	rcvr := self stackValue: 2.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(fmt = 3
	 and: [objectMemory isContextHeader: hdr])
		ifTrue: [self externalInstVar: index - 1 ofContext: rcvr put: newValue]
		ifFalse: [self subscript: rcvr with: index storing: newValue format: fmt].
	self pop: argumentCount + 1 thenPush: newValue
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveIntegerAt [
	"Return the 32bit signed integer contents of a words receiver"

	| index rcvr sz addr value intValue |
	<var: #intValue type: 'int'>
	index := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	((objectMemory isIntegerObject: rcvr)
	or: [(objectMemory isWords: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := objectMemory lengthOf: rcvr.  "number of fields"
	((index >= 1) and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize + (index - 1 * BytesPerWord). "for zero indexing"
	value := self intAt: addr.
	self pop: 2.  "pop rcvr, index"
	"push element value"
	(objectMemory isIntegerValue: value)
		ifTrue: [self pushInteger: value]
		ifFalse: [intValue := value. "32 bit int may have been stored in 32 or 64 bit sqInt"
				self push: (self signed32BitIntegerFor: intValue)] "intValue may be sign extended to 64 bit sqInt"
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveIntegerAtPut [
	"Return the 32bit signed integer contents of a words receiver"
	| index rcvr sz addr value valueOop |
	<var: 'value' type: 'int'>
	valueOop := self stackValue: 0.
	index := self stackIntegerValue: 1.
	value := self signed32BitValueOf: valueOop.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	((objectMemory isIntegerObject: rcvr)
	or: [(objectMemory isWords: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := objectMemory lengthOf: rcvr.  "number of fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize + (index - 1 * BytesPerWord). "for zero indexing"
	value := self intAt: addr put: value.
	self pop: 3 thenPush: valueOop "pop all; return value"

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
	arg := self popStack.
	(objectMemory fetchClassOf: arg) = (objectMemory splObj: ClassSemaphore)
		ifTrue: [objectMemory splObj: TheInterruptSemaphore put: arg]
		ifFalse: [objectMemory splObj: TheInterruptSemaphore put: objectMemory nilObject]
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitiveInvokeObjectAsMethod [
	"Primitive. 'Invoke' an object like a function, sending the special message 
		run: originalSelector with: arguments in: aReceiver.
	"
	<returnTypeC: #void>
	| runReceiver runArgs lookupClass |
	runArgs := objectMemory eeInstantiateClass: (objectMemory splObj: ClassArray) indexableSize: argumentCount.
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
	lookupClass := objectMemory fetchClassOf: newMethod.
	self findNewMethodInClass: lookupClass.
	self executeNewMethod.  "Recursive xeq affects successFlag"
	self initPrimCall
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveIsRoot [
	"Primitive. Answer whether the argument to the primitive is a root for young space"
	| oop |
	<export: true>
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
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver <= integerArgument
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
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver < integerArgument
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
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

	| outPointerArray segmentWordArray result |

	outPointerArray := self stackTop.
	segmentWordArray := self stackValue: 1.

	"Essential type checks"
	((objectMemory isArray: outPointerArray)		"Must be indexable pointers"
	 and: [objectMemory isWords: segmentWordArray])	"Must be indexable words"
		ifFalse: [^self primitiveFail].

	"the engine returns the roots array which was first in the segment, or 0 on failure"
	result := objectMemory loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray.
	result = 0
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: 3 thenPush: result]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveLocalMicrosecondClock [
	"Return the value of the microsecond clock as an integer.  The microsecond clock is at
	 least 60 bits wide which means it'll get to around August 38435 before it wraps around."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioLocalMicroseconds)
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveLogN [
	"Natural log."

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'log(rcvr)' inSmalltalk: [rcvr ln])]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveLowSpaceSemaphore [
	"Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore."
	| arg |
	arg := self popStack.
	(objectMemory fetchClassOf: arg) = (objectMemory splObj: ClassSemaphore)
		ifTrue: [objectMemory splObj: TheLowSpaceSemaphore put: arg]
		ifFalse: [objectMemory splObj: TheLowSpaceSemaphore put: objectMemory nilObject]
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveMakePoint [
	| rcvr argument pt |
	argument := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isIntegerObject: rcvr)
		ifTrue: [(objectMemory isIntegerObject: argument)
				ifTrue: [pt := self makePointwithxValue: (objectMemory integerValueOf: rcvr) yValue: (objectMemory integerValueOf: argument)]
				ifFalse: [pt := self makePointwithxValue: (objectMemory integerValueOf: rcvr) yValue: 0.
					"Above may cause GC!"
					objectMemory storePointer: 1 ofObject: pt withValue: (self stackValue: 0)]]
		ifFalse: [(self isFloatObject: rcvr)
				ifFalse: [^ self success: false].
			pt := self makePointwithxValue: 0 yValue: 0.
			"Above may cause GC!"
			objectMemory storePointer: 0 ofObject: pt withValue: (self stackValue: 1).
			objectMemory storePointer: 1 ofObject: pt withValue: (self stackValue: 0)].

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
	self pop: 1 thenPush: (self integerObjectOf: MillisecondClockMask)

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
	self pop: 1.
	pointWord := self ioMousePoint.
	x := self signExtend16: ((pointWord >> 16) bitAnd: 16rFFFF).
	y := self signExtend16: (pointWord bitAnd: 16rFFFF).
	self push: (self makePointwithxValue: x  yValue: y).
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveMultiply [
	| integerRcvr integerArg integerResult |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	self successful ifTrue:
		[integerResult := integerRcvr * integerArg.
		"check for C overflow by seeing if computation is reversible"
		((integerArg = 0) or: [(integerResult // integerArg) = integerRcvr])
			ifTrue: [self pop2AndPushIntegerIfOK: integerResult]
			ifFalse: [self primitiveFail]]
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
	"Allocate a new fixed-size instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC."
	| spaceOkay |
	"The following may cause GC!"
	spaceOkay := objectMemory sufficientSpaceToInstantiate: self stackTop indexableSize: 0.
	spaceOkay	ifTrue: [self
					pop: argumentCount + 1
					thenPush: (objectMemory instantiateClass: self stackTop indexableSize: 0)]
		ifFalse: [self primitiveFailFor: PrimErrNoMemory]
]

{ #category : #'compiled methods' }
InterpreterPrimitives >> primitiveNewMethod [
	| header bytecodeCount class size theMethod literalCount |
	header := self stackTop.
	bytecodeCount := self stackIntegerValue: 1.
	self success: (objectMemory isIntegerObject: header).
	self successful ifFalse: [^nil].
	class := self stackValue: 2.
	size := (self literalCountOfHeader: header) + 1 * BytesPerWord + bytecodeCount.
	theMethod := objectMemory instantiateClass: class indexableSize: size.
	objectMemory storePointerUnchecked: HeaderIndex ofObject: theMethod withValue: header.
	literalCount := self literalCountOfHeader: header.
	1 to: literalCount do:
		[:i | objectMemory storePointer: i ofObject: theMethod withValue: objectMemory nilObject].
	self pop: 3 thenPush: theMethod
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNewWithArg [
	"Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC."
	| size spaceOkay |
	size := self positive32BitValueOf: self stackTop.
	(self successful and: [size >= 0])
		ifTrue:
			[spaceOkay := objectMemory sufficientSpaceToInstantiate: (self stackValue: 1) indexableSize: size.
			 spaceOkay ifTrue:
					[self
						pop: argumentCount + 1
						thenPush: (objectMemory instantiateClass: (self stackValue: 1) indexableSize: size)]
				ifFalse:
					[self primitiveFailFor: PrimErrNoMemory]]
		ifFalse:
			[self primitiveFailFor: PrimErrBadArgument]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNextInstance [
	| object classPointer subsequentObject |
	object := self stackTop.
	(objectMemory isIntegerObject: object) ifFalse:
		[classPointer := objectMemory fetchClassOfNonInt: object.
		subsequentObject := objectMemory objectAfter: object.
		[self oop: subsequentObject isLessThan: objectMemory freeStart] whileTrue:
			[((objectMemory isFreeObject: subsequentObject) not
			  and: [(objectMemory fetchClassOfNonInt: subsequentObject) = classPointer]) ifTrue:
				[^self pop: argumentCount+1 thenPush: subsequentObject].
			 subsequentObject := objectMemory objectAfter: subsequentObject]].
	self primitiveFail
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveNextObject [
	"Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects."

	| object instance |
	object := self stackTop.
	instance := objectMemory accessibleObjectAfter: object.
	instance = nil
		ifTrue: [ self pop: argumentCount+1 thenPushInteger: 0 ]
		ifFalse: [ self pop: argumentCount+1 thenPush: instance ].
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveNoop [
	"A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver."

	self pop: argumentCount.  "pop args, leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
InterpreterPrimitives >> primitiveNotEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := (self compare31or32Bits: integerReceiver equal: integerArgument) not.
	self checkBooleanResult: result
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
	(index > 0 and: [index <= ((self literalCountOf: thisReceiver) + LiteralStart)]) ifFalse:
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
	(index > 0 and: [index <= ((self literalCountOf: thisReceiver) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	objectMemory storePointer: index - 1 ofObject: thisReceiver withValue: newValue.
	self pop: 3 thenPush: newValue
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitiveObjectPointsTo [
	"This primitive is assumed to be fast (see e.g. MethodDictionary>>includesKey:) so make it so.
	 N.B.  Written to use literalHeaderOf: so that in Cog subclasses cogged methods (whose headers
	 point to the machine code method) are still correctly scanned, for the header as well as literals."
	| rcvr thang header fmt lastField methodHeader |
	thang := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isIntegerObject: rcvr) ifTrue:
		[^self pop: 2 thenPushBool: false].

	"Inlined version of lastPointerOf: for speed in determining if rcvr is a context."
	header := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: header.
	fmt <= 4
		ifTrue:
			[(fmt = 3
			  and: [objectMemory isContextHeader: header]) 
				ifTrue:
	 				[(self isMarriedOrWidowedContext: rcvr) ifTrue:
						[self externalWriteBackHeadFramePointers.
						 (self isStillMarriedContext: rcvr) ifTrue:
							[^self pop: 2
									thenPushBool: (self marriedContext: rcvr
														pointsTo: thang
														stackDeltaForCurrentFrame: 2)]].
					"contexts end at the stack pointer"
					lastField := CtxtTempFrameStart + (self fetchStackPointerOf: rcvr) * BytesPerWord]
				ifFalse:
					[lastField := (objectMemory sizeBitsOfSafe: rcvr) - BaseHeaderSize]]
		ifFalse:
			[fmt < 12 "no pointers" ifTrue:
				[^self pop: 2 thenPushBool: false].
			"CompiledMethod: contains both pointers and bytes:"
			methodHeader := self headerOf: rcvr.
			methodHeader = thang ifTrue: [^self pop: 2 thenPushBool: true].
			lastField := ((self literalCountOfHeader: methodHeader) + 1) * BytesPerWord].

	BaseHeaderSize to: lastField by: BytesPerWord do:
		[:i |
		(self longAt: rcvr + i) = thang ifTrue:
			[^self pop: 2 thenPushBool: true]].
	self pop: 2 thenPushBool: false
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveOriginalMillisecondClock [
	"Return the value of the millisecond clock as an integer, using the old method prior to the 64-bit microsecond clock."
	<export: true>
	self pop: 1 thenPush: (objectMemory integerObjectOf: (self ioOldMSecs bitAnd: MillisecondClockMask))
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitivePerformInSuperclass [
	| lookupClass rcvr currentClass |
	lookupClass := self stackTop.
	rcvr := self stackValue: 3.
	currentClass := objectMemory fetchClassOf: rcvr.
	[currentClass ~= lookupClass] whileTrue:
		[currentClass := self superclassOf: currentClass.
		 currentClass = objectMemory nilObject ifTrue: [^self primitiveFailFor: PrimErrBadArgument]].

	self primitiveObject: rcvr "a.k.a. self stackValue: 3"
		perform: (self stackValue: 2)
		withArguments: (self stackValue: 1)
		lookedUpIn: lookupClass "a.k.a. self stackTop"
]

{ #category : #'control primitives' }
InterpreterPrimitives >> primitivePerformWithArgs [

	| lookupClass rcvr |
	rcvr := self stackValue: 2.
	lookupClass := objectMemory fetchClassOf: rcvr.

	self primitiveObject: rcvr "a.k.a. self stackValue: 2"
		perform: (self stackValue: 1)
		withArguments: self stackTop
		lookedUpIn: lookupClass
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitivePointX [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (objectMemory splObj: ClassPoint).
	self successful
		ifTrue: [self push: (objectMemory fetchPointer: XIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
InterpreterPrimitives >> primitivePointY [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (objectMemory splObj: ClassPoint).
	self successful
		ifTrue: [self push: (objectMemory fetchPointer: YIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
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
	self methodArgumentCount = 1 ifFalse:[^self success: false].
	sema := self stackValue: 0.
	sema = objectMemory nilObject ifFalse:[
		(objectMemory fetchClassOf: sema) = (objectMemory splObj: ClassSemaphore) 
			ifFalse:[^self success: false]].
	profileSemaphore := sema.
	profileProcess := profileMethod := objectMemory nilObject.
	self pop: 1.
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
	self successful ifTrue: [
		integerRcvr > 0 ifTrue: [
			integerArg > 0 ifTrue: [
				integerResult := integerRcvr // integerArg.
			] ifFalse: [
				integerResult := 0 - (integerRcvr // (0 - integerArg)).
			].
		] ifFalse: [
			integerArg > 0 ifTrue: [
				integerResult := 0 - ((0 - integerRcvr) // integerArg).
			] ifFalse: [
				integerResult := (0 - integerRcvr) // (0 - integerArg).
			].
		]].
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
	(self isContext: (objectMemory fetchPointer: SuspendedContextIndex ofObject: proc)) ifFalse:
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
	and: [self isContext: (objectMemory fetchPointer: SuspendedContextIndex ofObject: proc)]) ifFalse:
		[^self primitiveFail].
	self resume: proc preemptedYieldingIf: preemptionYields"
]

{ #category : #'memory space primitives' }
InterpreterPrimitives >> primitiveRootTable [
	"Primitive. Answer a copy (snapshot) element of the root table.
	The primitive can cause GC itself and if so the return value may
	be inaccurate - in this case one should guard the read operation
	by looking at the gc counter statistics."
	| oop sz |
	<export: true>
	sz := objectMemory rootTableCount.
	oop := objectMemory instantiateClass: objectMemory classArray indexableSize: sz. "can cause GC"
	sz > objectMemory rootTableCount ifTrue:[sz := objectMemory rootTableCount].
	1 to: sz do:[:i| 
		objectMemory storePointer: i-1 ofObject: oop withValue: (objectMemory rootTable at: i).
	].
	self pop: argumentCount + 1.
	self push: oop.
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
	| index |
	<export: true>
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
	| kernDelta stops sourceString scanStopIndex scanStartIndex rcvr scanDestX scanLastIndex scanXTable scanMap maxGlyph ascii stopReason glyphIndex sourceX sourceX2 nextDestX scanRightX nilOop |

	self methodArgumentCount = 6
		ifFalse: [^ self primitiveFail].

	"Load the arguments"
	kernDelta := self stackIntegerValue: 0.
	stops := self stackObjectValue: 1.
	(objectMemory isArray: stops) ifFalse: [^ self primitiveFail].
	(objectMemory slotSizeOf: stops) >= 258 ifFalse: [^ self primitiveFail].
	scanRightX := self stackIntegerValue: 2.
	sourceString := self stackObjectValue: 3.
	(objectMemory isBytes: sourceString) ifFalse: [^ self primitiveFail].
	scanStopIndex := self stackIntegerValue: 4.
	scanStartIndex := self stackIntegerValue: 5.
	(scanStartIndex > 0 and: [scanStopIndex > 0 and: [scanStopIndex <= (objectMemory byteSizeOf: sourceString)]])
		ifFalse: [^ self primitiveFail].

	"Load receiver and required instVars"
	rcvr := self stackObjectValue: 6.
	((objectMemory isPointers: rcvr) and: [(objectMemory slotSizeOf: rcvr) >= 4]) ifFalse: [^ self primitiveFail].
	scanDestX := self fetchInteger: 0 ofObject: rcvr.
	scanLastIndex := self fetchInteger: 1 ofObject: rcvr.
	scanXTable := objectMemory fetchPointer: 2 ofObject: rcvr.
	scanMap := objectMemory fetchPointer: 3 ofObject: rcvr.
	((objectMemory isArray: scanXTable) and: [objectMemory isArray: scanMap]) ifFalse: [^ self primitiveFail].
	(objectMemory slotSizeOf: scanMap) = 256 ifFalse: [^ self primitiveFail].
	self successful ifFalse: [^ nil].
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
					self pop: 7. "args+rcvr"
					^ self push: stopReason].
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
InterpreterPrimitives >> primitiveScreenSize [
	"Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day"
	| pointWord |
	self pop: 1.
	pointWord := self ioScreenSize.
	self push: (self makePointwithxValue: (pointWord >> 16 bitAnd: 65535) yValue: (pointWord bitAnd: 65535))
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveSecondsClock [
	"Return the number of seconds since January 1, 1901 as an integer."

	self pop: 1 thenPush: (self positive32BitIntegerFor: self ioSeconds).
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
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Return the contents of the given index. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	index := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	((objectMemory isIntegerObject: rcvr)
	or: [(objectMemory isWordsOrBytes: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := ((objectMemory sizeBitsOf: rcvr) - BaseHeaderSize) // 2.  "number of 16-bit fields"
	((index >= 1) and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize + (2 * (index - 1)).
	value := objectMemory shortAt: addr.
	self pop: 2 thenPushInteger: value
]

{ #category : #'sound primitives' }
InterpreterPrimitives >> primitiveShortAtPut [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Set the contents of the given index to the given value. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	value := self stackIntegerValue: 0.
	index := self stackIntegerValue: 1.
	(self successful and: [(value >= -32768) and: [value <= 32767]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	((objectMemory isIntegerObject: rcvr) not and: [objectMemory isWordsOrBytes: rcvr]) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := ((objectMemory sizeBitsOf: rcvr) - BaseHeaderSize) // 2.  "number of 16-bit fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize + (2 * (index - 1)).
	objectMemory shortAt: addr put: value.
	self pop: 3 thenPush: (objectMemory integerObjectOf: value) "pop all; return value"
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
	self displayBitsOf: (objectMemory splObj: TheDisplay) Left: left Top: top Right: right Bottom: bottom.
	self successful
		ifTrue: [self ioForceDisplayUpdate.
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
	"Set the low-water mark for free space. When the free space 
	falls below this level, the new and new: primitives fail and 
	system attempts to allocate space (e.g., to create a method 
	context) cause the low-space semaphore (if one is 
	registered) to be signalled."
	| bytes |
	bytes := self popInteger.
	self successful
		ifTrue: [objectMemory lowSpaceThreshold: bytes]
		ifFalse: [objectMemory lowSpaceThreshold: 0.
			self unPop: 1]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSine [

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'sin(rcvr)' inSmalltalk: [rcvr sin])]
		ifFalse: [self unPop: 1]
]

{ #category : #'indexing primitives' }
InterpreterPrimitives >> primitiveSize [
	| rcvr hdr fmt fixedFields totalLength |
	rcvr := self stackTop.
	((objectMemory isIntegerObject: rcvr) "Integers are not indexable"
	 or: [hdr := objectMemory baseHeader: rcvr.
		(fmt := objectMemory formatOfHeader: hdr) < 2]) "This is not an indexable object"
		ifTrue:
			[^self primitiveFailFor: PrimErrBadReceiver].
	(fmt = 3 and: [objectMemory isContextHeader: hdr]) ifTrue:
		[^self primitiveContextSize].
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: totalLength - fixedFields)
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
	instance := objectMemory initialInstanceOf: class.
	instance = objectMemory nilObject
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount+1 thenPush: instance]
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

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveSquareRoot [
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self success: rcvr >= 0.0.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'sqrt(rcvr)' inSmalltalk: [rcvr sqrt])]
		ifFalse: [self unPop: 1]
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
	((vmHistArrayOrNil = objectMemory nilObject or: [(objectMemory fetchClassOfNonInt: vmHistArrayOrNil) = (objectMemory splObj: ClassArray)])
	 and: [(objectMemory fetchClassOfNonInt: vmHistArrayOrNil) = (objectMemory fetchClassOfNonInt: easHistArrayOrNil)]) ifFalse:
		[^self primitiveFail].
	self cCode: 'ioControlProfile(0,&vmHist,&vmBins,&easHist,&easBins)'
		inSmalltalk: [vmHist := vmBins := easHist := easBins := 0].
	vmHistArrayOrNil ~= objectMemory nilObject ifTrue:
		[((objectMemory fetchWordLengthOf: vmHistArrayOrNil) = vmBins
		  and: [(objectMemory fetchWordLengthOf: easHistArrayOrNil) = easBins]) ifFalse:
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
	" 
	<array> primReplaceFrom: start to: stop with: replacement 
	startingAt: repStart  
	<primitive: 105>
	"
	| array start stop repl replStart hdr arrayFmt totalLength arrayInstSize replFmt replInstSize srcIndex |
	array := self stackValue: 4.
	start := self stackIntegerValue: 3.
	stop := self stackIntegerValue: 2.
	repl := self stackValue: 1.
	replStart := self stackIntegerValue: 0.

	self successful ifFalse: [^ self primitiveFail].
	(objectMemory isIntegerObject: repl) ifTrue: ["can happen in LgInt copy"
			^ self primitiveFail].

	hdr := objectMemory baseHeader: array.
	arrayFmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: array baseHeader: hdr format: arrayFmt.
	arrayInstSize := objectMemory fixedFieldsOf: array format: arrayFmt length: totalLength.
	(start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= totalLength]])
		ifFalse: [^ self primitiveFailFor: PrimErrBadIndex].

	hdr := objectMemory baseHeader: repl.
	replFmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: repl baseHeader: hdr format: replFmt.
	replInstSize := objectMemory fixedFieldsOf: repl format: replFmt length: totalLength.
	(replStart >= 1 and: [stop - start + replStart + replInstSize <= totalLength])
		ifFalse: [^ self primitiveFailFor: PrimErrBadIndex].

	"Array formats (without byteSize bits, if bytes array) must be same "
	arrayFmt < 8
		ifTrue: [arrayFmt = replFmt
				ifFalse: [^ self primitiveFailFor: PrimErrInappropriate]]
		ifFalse: [(arrayFmt bitAnd: 12) = (replFmt bitAnd: 12)
				ifFalse: [^ self primitiveFailFor: PrimErrInappropriate]].

	srcIndex := replStart + replInstSize - 1.
	"- 1 for 0-based access"

	arrayFmt <= 4
		ifTrue: ["pointer type objects"
			start + arrayInstSize - 1 to: stop + arrayInstSize - 1 do: [:i |
				objectMemory storePointer: i ofObject: array withValue: (objectMemory fetchPointer: srcIndex ofObject: repl).
					srcIndex := srcIndex + 1]]
		ifFalse: [arrayFmt < 8
				ifTrue: ["32-bit-word type objects"
					start + arrayInstSize - 1 to: stop + arrayInstSize - 1
						do: [:i | objectMemory storeLong32: i ofObject: array withValue: (objectMemory fetchLong32: srcIndex ofObject: repl).
							srcIndex := srcIndex + 1]]
				ifFalse: ["byte-type objects"
					start + arrayInstSize - 1 to: stop + arrayInstSize - 1
						do: [:i |  objectMemory storeByte: i ofObject: array withValue: (objectMemory fetchByte: srcIndex ofObject: repl).
							srcIndex := srcIndex + 1]]].
	"We might consider  comparing stop - start to some value here and using forceInterruptCheck"

	self pop: argumentCount "leave rcvr on stack"
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
	process = self activeProcess ifTrue:[
		self pop: 1 thenPush: objectMemory nilObject.
		self transferTo: self wakeHighestPriority.
	] ifFalse:[
		myList := objectMemory fetchPointer: MyListIndex ofObject: process.
		"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
		but we can't easily so just do a quick check for nil which is the most common case."
		myList = objectMemory nilObject ifTrue:[^self primitiveFail].
		self removeProcess: process fromList: myList.
		self successful ifTrue:[
			objectMemory storePointer: MyListIndex ofObject: process withValue: objectMemory nilObject.
			self pop: 1 thenPush: myList.
		].
	]
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

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveTimesTwoPower [
	| rcvr arg |
	<var: #rcvr type: #double>
	arg := self popInteger.
	rcvr := self popFloat.
	self successful
		ifTrue: [ self pushFloat: (self cCode: 'ldexp(rcvr, arg)' inSmalltalk: [rcvr timesTwoPower: arg]) ]
		ifFalse: [ self unPop: 2 ]
]

{ #category : #'arithmetic float primitives' }
InterpreterPrimitives >> primitiveTruncated [ 
	| rcvr frac trunc |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #trunc type: #double>
	rcvr := self popFloat.
	self successful ifTrue:
		[self cCode: 'frac = modf(rcvr, &trunc)'
			inSmalltalk: [trunc := rcvr truncated].
		self flag: #Dan.		"The ranges are INCORRECT if SmallIntegers are wider than 31 bits."
		self cCode: 'success((-1073741824.0 <= trunc) && (trunc <= 1073741823.0))'
			inSmalltalk: [self success: (trunc between: SmallInteger minVal and: SmallInteger maxVal)]].
	self successful
		ifTrue: [self cCode: 'pushInteger((sqInt) trunc)' inSmalltalk: [self pushInteger: trunc]]
		ifFalse: [self unPop: 1]
]

{ #category : #'system control primitives' }
InterpreterPrimitives >> primitiveUTCMicrosecondClock [
	"Return the value of the microsecond clock as an integer.  The microsecond clock is at
	 least 60 bits wide which means it'll get to around August 38435 before it wraps around."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioUTCMicroseconds)
]

{ #category : #'plugin primitives' }
InterpreterPrimitives >> primitiveUnloadModule [
	"Primitive. Unload the module with the given name."
	"Reloading of the module will happen *later* automatically, when a 
	function from it is called. This is ensured by invalidating current sessionID."
	| moduleName |
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	moduleName := self stackTop.
	(objectMemory isIntegerObject: moduleName) ifTrue:[^self primitiveFail].
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
InterpreterPrimitives >> primitiveUtcWithOffset [
	"Answer an array with UTC microseconds since the Posix epoch and
	the current seconds offset from GMT in the local time zone.
	This is a named (not numbered) primitive in the null module (ie the VM)"
	| offset resultArray |

	<export: true>
	<var: #clock type: 'sqLong'>
	offset := self ioUTCMicroseconds - self ioLocalMicroseconds.
	objectMemory pushRemappableOop: (self positive64BitIntegerFor: self ioUTCMicroseconds).
	resultArray := objectMemory instantiateClass: objectMemory classArray indexableSize: 2.
	self stObject: resultArray at: 1 put: objectMemory popRemappableOop.
	self stObject: resultArray at: 2 put: (objectMemory integerObjectOf: offset).
	self pop: 1 thenPush: resultArray

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
	self vmPathGet: (s + BaseHeaderSize) Length: sz.
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
		[info := self stackObjectValue: 0.
		 info ~= objectMemory nilObject ifTrue:
			[self assertClassOf: info is: (objectMemory splObj: ClassArray).
			 self success: (objectMemory fetchWordLengthOf: info) >= 4]].
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
	| sampleBuffer sampleBufferAddress running bufferSize numSamples |
	<var: #bufferSize type: #long>
	<var: #sampleBufferAddress type: #'unsigned long *'>
	self cCode: 'ioNewProfileStatus(&running,&bufferSize)'
		inSmalltalk: [running := false. bufferSize := 0].
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPushBool: running].
	self success: argumentCount = 1.
	self successful ifTrue:
		[sampleBuffer := self stackObjectValue: 0.
		 self assertClassOf: sampleBuffer is: (objectMemory splObj: ClassBitmap).
		 self success: (objectMemory fetchWordLengthOf: sampleBuffer) >= bufferSize].
	self successful ifFalse:
		[^nil].
	sampleBufferAddress := objectMemory firstFixedField: sampleBuffer.
	numSamples := self cCode: 'ioNewProfileSamplesInto(sampleBufferAddress)'
						inSmalltalk: [sampleBufferAddress := sampleBufferAddress].
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
"primitively do the equivalent of Process>yield"
	| activeProc priority processLists processList |
	activeProc := self activeProcess.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := objectMemory fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifFalse:[
		self addLastLink: activeProc toList: processList.
		self transferTo: self wakeHighestPriority]
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
	The object may be either a positive SmallInteger or a four-byte LargeInteger."
	| value negative ok |
	<inline: false>
	<returnTypeC: #int>
	<var: #value type: #int>
	(objectMemory isIntegerObject: oop) ifTrue:
		[^objectMemory integerValueOf: oop].

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
	(objectMemory lengthOf: oop) > 4 ifTrue:
		[^self primitiveFail].

	value :=  (objectMemory fetchByte: 0 ofObject: oop) +
			  ((objectMemory fetchByte: 1 ofObject: oop) <<  8) +
			  ((objectMemory fetchByte: 2 ofObject: oop) << 16) +
			  ((objectMemory fetchByte: 3 ofObject: oop) << 24).
	self cCode: []
		inSmalltalk:
			[(value anyMask: 16r80000000) ifTrue:
				[value := value - 16r100000000]].
	"Filter out values out of range for the signed interpretation such as
	 16rFFFFFFFF (positive w/ bit 32 set) and -16rFFFFFFFF (negative w/ bit
	 32 set). Since the sign is implicit in the class we require that the high
	 bit of the magnitude is not set which is a simple test here.  Note that
	 we have to handle the most negative 32-bit value -2147483648 specially."
	value < 0 ifTrue:
		[self assert: (self sizeof: value) == 4.
		 "Don't fail for -16r80000000/-2147483648
		  Alas the simple (negative and: [value - 1 > 0]) isn't adequate since in C the result of signed integer
		  overflow is undefined and hence under optimization this may fail.  The shift, however, is well-defined."
		 (negative and: [0 = (self cCode: [value << 1]
									inSmalltalk: [value << 1 bitAnd: (1 << 32) - 1])]) ifTrue: 
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue: [0 - value]
		ifFalse: [value]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> signed64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive SmallInteger or a eight-byte LargeInteger."
	| sz value negative ok |
	<inline: false>
	<returnTypeC: #sqLong>
	<var: #value type: #sqLong>
	(objectMemory isIntegerObject: oop) ifTrue:
		[^self cCoerce: (objectMemory integerValueOf: oop) to: #sqLong].

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
	sz := objectMemory lengthOf: oop.
	sz > (self sizeof: #sqLong) ifTrue:
		[^self primitiveFail].

	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (objectMemory fetchByte: i ofObject: oop) to: #sqLong) <<  (i*8))].
	"Filter out values out of range for the signed interpretation such as
	16rFFFFFFFF... (positive w/ bit 64 set) and -16rFFFFFFFF... (negative w/ bit
	64 set). Since the sign is implicit in the class we require that the high bit of
	the magnitude is not set which is a simple test here.  Note that we have to
	handle the most negative 64-bit value -9223372036854775808 specially."
	self cCode: []
		inSmalltalk:
			[(value anyMask: 16r8000000000000000) ifTrue:
				[value := value - 16r10000000000000000]].
	value < 0 ifTrue:
		[self cCode:
			[self assert: (self sizeof: value) == 8.
			 self assert: (self sizeof: value << 1) == 8].
		"Don't fail for -9223372036854775808/-16r8000000000000000.
		 Alas the simple (negative and: [value - 1 > 0]) isn't adequate since in C the result of signed integer
		  overflow is undefined and hence under optimization this may fail.  The shift, however, is well-defined."
		 (negative and: [0 = (self cCode: [value << 1]
									inSmalltalk: [value << 1 bitAnd: (1 << 64) - 1])]) ifTrue: 
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue:[0 - value]
		ifFalse:[value]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> signedMachineIntegerValueOf: oop [
	"Answer a signed value of an integer up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargeInteger of size <= word size."
	<returnTypeC: #'long'>
	| negative ok bs value bits |
	<var: #value type: #long>
	(objectMemory isIntegerObject: oop) ifTrue:
		[^objectMemory integerValueOf: oop].

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
	(bs := objectMemory lengthOf: oop) > (self sizeof: #'unsigned long') ifTrue:
		[^self primitiveFail].

	((self sizeof: #'unsigned long') = 8
	 and: [bs > 4])
		ifTrue:
			[value :=   (objectMemory fetchByte: 0 ofObject: oop)
					+ ((objectMemory fetchByte: 1 ofObject: oop) <<  8)
					+ ((objectMemory fetchByte: 2 ofObject: oop) << 16)
					+ ((objectMemory fetchByte: 3 ofObject: oop) << 24)
					+ ((objectMemory fetchByte: 4 ofObject: oop) << 32)
					+ ((objectMemory fetchByte: 5 ofObject: oop) << 40)
					+ ((objectMemory fetchByte: 6 ofObject: oop) << 48)
					+ ((objectMemory fetchByte: 7 ofObject: oop) << 56)]
		ifFalse:
			[value :=   (objectMemory fetchByte: 0 ofObject: oop)
					+ ((objectMemory fetchByte: 1 ofObject: oop) <<  8)
					+ ((objectMemory fetchByte: 2 ofObject: oop) << 16)
					+ ((objectMemory fetchByte: 3 ofObject: oop) << 24)].

	
	self cCode: []
		inSmalltalk:
			[bits := (self sizeof: #long) * 8.
			 (value bitShift: 1 - bits) > 0 ifTrue:
				[value := value - (1 bitShift: bits)]].
	value < 0 ifTrue:
		["Don't fail for -16r80000000[00000000].
		  Alas the simple (negative and: [value - 1 > 0]) isn't adequate since in C the result of signed integer
		  overflow is undefined and hence under optimization this may fail.  The shift, however, is well-defined."
		 (negative and: [0 = (self cCode: [value << 1]
									inSmalltalk: [value << 1 bitAnd: (1 << bits) - 1])]) ifTrue: 
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue: [0 - value]
		ifFalse: [value]
]

{ #category : #'primitive support' }
InterpreterPrimitives >> sizeFieldOfAlien: alienObj [
	"Answer the first field of alienObj which is assumed to be an Alien of at least 8 bytes"
	<inline: true>
	^self longAt: alienObj + BaseHeaderSize
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
						 	ifTrue: [oop + BaseHeaderSize + BytesPerOop]
							ifFalse: [self longAt: oop + BaseHeaderSize + BytesPerOop])
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
