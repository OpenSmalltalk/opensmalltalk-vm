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
	self assert: (self isYoungRoot: anOop) not.
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

{ #category : #become }
NewCoObjectMemory >> freeObject: obj [
	self assert: ((self isCompiledMethod: obj) not or: [(self methodHasCogMethod: obj) not]).
	super freeObject: obj
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
	 N.B. the stack zone is alloca'ed. Use a macro so as not to punish the debug VM."
	<cmacro: '() heapBase'>
	<returnTypeC: #usqInt>
	^coInterpreter heapBase
]

{ #category : #'trampoline support' }
NewCoObjectMemory >> youngStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: youngStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #youngStart in: self]
]
