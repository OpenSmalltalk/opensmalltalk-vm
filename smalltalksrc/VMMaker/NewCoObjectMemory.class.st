Class {
	#name : #NewCoObjectMemory,
	#superclass : #NewObjectMemory,
	#instVars : [
		'cogit'
	],
	#pools : [
		'CogMethodConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #simulation }
NewCoObjectMemory class >> simulatorClass [
	^NewCoObjectMemorySimulator
]

{ #category : #trampolines }
NewCoObjectMemory >> ceStoreCheck: anOop [
	<api>
	"Do the store check.  Answer the argument for the benefit of the code generator;
	ReceiverResultReg may be caller-saved and hence smashed by this call.  Answering
	it allows the code generator to reload ReceiverResultReg cheaply."
	self assert: (self isNonIntegerObject: anOop).
	self assert: (self oop: anOop isLessThan: self youngStart).
	self assert: ((self baseHeader: anOop) bitAnd: RootBit) = 0.
	self noteAsRoot: anOop headerLoc: anOop.
	^anOop
]

{ #category : #'object enumeration' }
NewCoObjectMemory >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header.
	 Override to set a bit at each Cog method"
	| obj sz nextHeader |
	<inline: false>
	<var: #obj type: #usqInt>
	<var: #sz type: #usqInt>
	<var: #nextHeader type: #usqInt>
	self clearHeapMap.
	obj := self firstObject.
	[obj < freeStart] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[self heapMapAtWord: (self pointerForOop: obj) Put: 1.
				 sz := self sizeBitsOf: obj].
		nextHeader := obj + sz.
		obj := self oopFromChunk: nextHeader].
	cogit addCogMethodsToHeapMap
]

{ #category : #accessing }
NewCoObjectMemory >> cogit [
	<doNotGenerate>
	^cogit
]

{ #category : #accessing }
NewCoObjectMemory >> cogit: aCogit [
	cogit := aCogit
]

{ #category : #'cog jit support' }
NewCoObjectMemory >> compactClassTable [
	<api>
	^self splObj: CompactClasses
]

{ #category : #'image segment in/out' }
NewCoObjectMemory >> copyObj: oop toSegment: segmentWordArray addr: lastSeg stopAt: stopAddr saveOopAt: oopPtr headerAt: hdrPtr [
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

	"Make sure Cogged methods have their true header field written to the segment."
	((self isCompiledMethod: oop)
	and: [self methodHasCogMethod: oop]) ifTrue:
		[self longAt: hdrAddr+BaseHeaderSize put: (self headerOf: oop)].

	self forward: oop to: (lastSeg+BytesPerWord + extraSize - segmentWordArray)
		savingOopAt: oopPtr
		andHeaderAt: hdrPtr.

	"Return new end of segment"
	^lastSeg + extraSize + bodySize
]

{ #category : #'trampoline support' }
NewCoObjectMemory >> freeStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: freeStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #freeStart in: self]
]

{ #category : #allocation }
NewCoObjectMemory >> growObjectMemory: delta [ 
	"Attempt to grow the object memory by the given delta amount."
	| limit |
	statGrowMemory := statGrowMemory + 1.
	limit := self sqGrowMemory: memoryLimit By: delta.
	limit = memoryLimit ifFalse:
		[self setMemoryLimit: limit - 24. "remove a tad for safety"
		 self initializeMemoryFirstFree: freeStart.
		 coInterpreter sqMakeMemoryNotExecutableFrom: self startOfMemory To: memoryLimit]
]

{ #category : #'object enumeration' }
NewCoObjectMemory >> lastPointerOf: oop [ 
	"Return the byte offset of the last pointer field of the given object.  
	 Can be used even when the type bits are not correct.
	 Works with CompiledMethods, as well as ordinary objects.
	 Override to handle hidden pointer to CogMethod in a CompiledMethod header field."
	| fmt methodHeader header contextSize |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: oop.
			^CtxtTempFrameStart + contextSize * BytesPerWord].
		^(self sizeBitsOfSafe: oop) - BaseHeaderSize  "all pointers"].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes; may have an associated CogMethod"
	methodHeader := self longAt: oop + BaseHeaderSize.
	(coInterpreter isCogMethodReference: methodHeader) ifTrue:
		[self assert: (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') cmType = CMMethod.
		 methodHeader := (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader].
	^(coInterpreter literalCountOfHeader:methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'object enumeration' }
NewCoObjectMemory >> lastPointerOf: oop recordWeakRoot: recordWeakRoot [ "<Boolean>"
	"Return the byte offset of the last pointer field of the given object.  
	 Works with CompiledMethods, as well as ordinary objects. 
	 Can be used even when the type bits are not correct.
	 This is a version of lastPointerOf: for markAndTrace:.
	 Already overridden to trace stack pages for the StackInterpreter.
	 Override to handle hidden pointer to CogMethod in a
	 CompiledMethod header field."
	| fmt sz header contextSize methodHeader |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[fmt >= 3 ifTrue:
			[fmt = 4 ifTrue:
				[recordWeakRoot ifTrue:
					["And remember as weak root"
					 weakRootCount := weakRootCount + 1.
					 self assert: weakRootCount <= WeakRootTableSize.
					 weakRoots at: weakRootCount put: oop].
				"Do not trace the object's indexed fields if it's a weak class"
				^(self nonWeakFieldsOf: oop) << ShiftForWord].
			"So fmt is 3"
			(self isContextHeader: header) ifTrue:
				[coInterpreter setTraceFlagOnContextsFramesPageIfNeeded: oop.
				 "contexts end at the stack pointer avoiding having to init fields beyond it"
				 contextSize := coInterpreter fetchStackPointerOf: oop.
				 self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
				 ^CtxtTempFrameStart + contextSize * BytesPerWord]].
		 sz := self sizeBitsOfSafe: oop.
		 ^sz - BaseHeaderSize  "all pointers" ].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes; may have an associated CogMethod"
	methodHeader := self longAt: oop + BaseHeaderSize.
	(coInterpreter isCogMethodReference: methodHeader) ifTrue:
		[self assert: (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') cmType = CMMethod.
		 methodHeader := (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader].
	^(coInterpreter literalCountOfHeader: methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'gc -- compaction' }
NewCoObjectMemory >> lastPointerWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	 the offset of the last pointer in the object in spite of this obstacle."
	| header fmt size methodHeader contextSize |
	<inline: true>
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			 contextSize := coInterpreter nacFetchStackPointerOf: oop.
			 self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
			 ^CtxtTempFrameStart + contextSize * BytesPerWord].
		 "do sizeBitsOf: using the header we obtained"
		 size := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
					ifTrue: [(self sizeHeader: oop) bitAnd: AllButTypeMask]
					ifFalse: [header bitAnd: SizeMask].
		 ^size - BaseHeaderSize].
	fmt < 12 ifTrue: [^0]. "no pointers"
	methodHeader := self longAt: oop + BaseHeaderSize.
	(coInterpreter isCogMethodReference: methodHeader) ifTrue:
		[self assert: (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') cmType = CMMethod.
		 methodHeader := (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader].
	^(coInterpreter literalCountOfHeader: methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'gc -- compaction' }
NewCoObjectMemory >> nullHeaderForMachineCodeMethod [
	<api>
	^(1 << 12 "CompactClassIndex 1") + HeaderTypeShort
]

{ #category : #'trampoline support' }
NewCoObjectMemory >> scavengeThresholdAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: scavengeThreshold) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #scavengeThreshold in: self]
]

{ #category : #accessing }
NewCoObjectMemory >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed."
	<api>
	^coInterpreter heapBase
]

{ #category : #'trampoline support' }
NewCoObjectMemory >> youngStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: youngStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #youngStart in: self]
]
