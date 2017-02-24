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
NewCoObjectMemory class >> defaultISA [
	"Answer the default instruction set architecture to use for simulation."
	^#IA32
]

{ #category : #'accessing class hierarchy' }
NewCoObjectMemory class >> objectRepresentationClass [
	^CogObjectRepresentationForSqueakV3
]

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

{ #category : #'debug support' }
NewCoObjectMemory >> cheapAddressCouldBeInHeap: address [ 
	^(address bitAnd: self wordSize - 1) = 0
	  and: [(self oop: address isGreaterThanOrEqualTo: self startOfMemory)
	  and: [self oop: address isLessThan: freeStart]]
]

{ #category : #'debug support' }
NewCoObjectMemory >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header.
	 Override to set a bit at each Cog method"
	super clearLeakMapAndMapAccessibleObjects.
	cogit addCogMethodsToHeapMap
]

{ #category : #accessing }
NewCoObjectMemory >> coInterpreter [
	<doNotGenerate>
	^coInterpreter
]

{ #category : #accessing }
NewCoObjectMemory >> coInterpreter: aCoInterpreter [
	<doNotGenerate>
	coInterpreter := aCoInterpreter
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
	self transfer: extraSize + bodySize // self wordSize  "wordCount"
		from: oop - extraSize
		to: lastSeg+self wordSize.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr := lastSeg+self wordSize + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: AllButRootBit - MarkBit).

	"Make sure Cogged methods have their true header field written to the segment."
	((self isCompiledMethod: oop)
	and: [coInterpreter methodHasCogMethod: oop]) ifTrue:
		[self longAt: hdrAddr+self baseHeaderSize put: (self methodHeaderOf: oop)].

	self forward: oop to: (lastSeg+self wordSize + extraSize - segmentWordArray)
		savingOopAt: oopPtr
		andHeaderAt: hdrPtr.

	"Return new end of segment"
	^lastSeg + extraSize + bodySize
]

{ #category : #become }
NewCoObjectMemory >> freeObject: obj header: objHeader [
	(self isCompiledMethodHeader: objHeader) ifTrue:
		[(self asserta: (coInterpreter methodHasCogMethod: obj) not) ifFalse:
			[self error: 'attempt to free cogged method']].
	super freeObject: obj header: objHeader
]

{ #category : #accessing }
NewCoObjectMemory >> freeStart: aValue [
	^freeStart := aValue
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

{ #category : #simulation }
NewCoObjectMemory >> initializeFreeSpaceForFacadeFrom: base to: limit [
	freeStart := base.
	endOfMemory := scavengeThreshold := limit
]

{ #category : #'cog jit support' }
NewCoObjectMemory >> isReallyYoungObject: obj [
	<api>
	"For machine code assertion checking.  Answer true if not in a fullGC and obj is young."
	^coInterpreter gcMode ~= GCModeFull
	  and: [self oop: obj isGreaterThanOrEqualTo: self youngStart]
]

{ #category : #'image save/restore' }
NewCoObjectMemory >> memoryBaseForImageRead [
	"Answer the address to read the image into."
	^coInterpreter heapBase
]

{ #category : #'memory access' }
NewCoObjectMemory >> methodHeaderOf: methodObj [
	"Answer the method header of a CompiledMethod object.
	 If the method has been cogged then the header is a pointer to
	 the CogMethod and the real header will be stored in the CogMethod."
	<api>
	<inline: true>
	| header |
	self assert: (self isCompiledMethod: methodObj).
	header := self fetchPointer: HeaderIndex ofObject: methodObj.
	^(self isIntegerObject: header)
		ifTrue: [header]
		ifFalse:
			[self assert: header asUnsignedInteger < coInterpreter heapBase.
			 self assert: (coInterpreter cCoerceSimple: header to: #'CogMethod *') objectHeader
						= self nullHeaderForMachineCodeMethod.
			(coInterpreter cCoerceSimple: header to: #'CogMethod *') methodHeader]
]

{ #category : #'memory access' }
NewCoObjectMemory >> noCheckMethodHeaderOf: methodObj [
	"Answer the method header of a CompiledMethod object.
	 If the method has been cogged then the header is a pointer to
	 the CogMethod and the real header will be stored in the CogMethod."
	<inline: true>
	| header |
	header := self fetchPointer: HeaderIndex ofObject: methodObj.
	^(self isIntegerObject: header)
		ifTrue: [header]
		ifFalse:
			[self assert: header asUnsignedInteger < coInterpreter heapBase.
			 self assert: (coInterpreter cCoerceSimple: header to: #'CogMethod *') objectHeader
						= self nullHeaderForMachineCodeMethod.
			(coInterpreter cCoerceSimple: header to: #'CogMethod *') methodHeader]
]

{ #category : #'cog jit support' }
NewCoObjectMemory >> noShiftCompactClassIndexOf: oop [
	<api>
	^(self baseHeader: oop) bitAnd: 16r1F << self compactClassFieldLSB
]

{ #category : #'gc -- compaction' }
NewCoObjectMemory >> nullHeaderForMachineCodeMethod [
	<api>
	^(1 << 12 "CompactClassIndex 1") + HeaderTypeShort
]

{ #category : #'cog jit support' }
NewCoObjectMemory >> receiverTagBitsForMethod: aMethodObj [
	"Answer the tag bits for the receiver based on the method's methodClass, if any."
	<api>
	^(coInterpreter methodClassOf: aMethodObj) = self classSmallInteger
		ifTrue: [self smallIntegerTag]
		ifFalse: [0]
]

{ #category : #become }
NewCoObjectMemory >> restoreHeaderOf: obj to: objHeader [
	super restoreHeaderOf: obj to: objHeader.
	(self isCompiledMethodHeader: objHeader) ifTrue:
		[(self asserta: ((coInterpreter methodHasCogMethod: obj) not
						or: [obj = (coInterpreter cogMethodOf: obj) methodObject])) ifFalse:
			[self error: 'attempt to become cogged method']]
]

{ #category : #'trampoline support' }
NewCoObjectMemory >> scavengeThresholdAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: scavengeThreshold) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #scavengeThreshold in: self]
]

{ #category : #'cog jit support' }
NewCoObjectMemory >> smallIntegerTag [
	<api>
	^1
]

{ #category : #accessing }
NewCoObjectMemory >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed. Use a macro so as not to punish the debug VM."
	<cmacro: '() heapBase'>
	<returnTypeC: #usqInt>
	^coInterpreter heapBase
]

{ #category : #simulation }
NewCoObjectMemory >> validate: oop [
	<doNotGenerate>
	| header type cc sz fmt nextChunk | 
	header := self longAt: oop.
	type := header bitAnd: 3.
	type = 2 ifFalse: [type = (self rightType: header) ifFalse: [self halt]].
	sz := (header bitAnd: SizeMask) >> 2.
	nextChunk := oop + ((self isFreeObject: oop)
							ifTrue: [self sizeOfFree: oop]
							ifFalse: [self sizeBitsOf: oop]).
	nextChunk >= freeStart
		ifTrue:
			[nextChunk ~= freeStart ifTrue: [self halt]]
		ifFalse:
			[(self headerType: nextChunk) = 0 ifTrue:
				[(self headerType: (nextChunk + (self wordSize*2))) = 0 ifFalse: [self halt]].
			(self headerType: nextChunk) = 1 ifTrue:
				[(self headerType: (nextChunk + self wordSize)) = 1 ifFalse: [self halt]]].
	type = 2 ifTrue: "free block"
		[^self].
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
	fmt >= self firstCompiledMethodFormat ifTrue: "must have integer header or be cog method"
		[header := self longAt: oop + self wordSize.
		 ((self isIntegerObject: header)
		  or: [(header bitAnd: 7) = 0
			and: [header asUnsignedInteger < self startOfMemory
			and: [header asUnsignedInteger >= cogit minCogMethodAddress]]]) ifFalse: [self halt]].
]

{ #category : #'cog jit support' }
NewCoObjectMemory >> withoutForwardingOn: obj1 and: obj2 with: aBool sendToCogit: selector [
	"For the purposes of become: send selector to the cogit with obj1, obj2 and aBool, and
	 answer the result. Undo forwarding for the selector, but redo forwarding after since
	 become:'s restoreHeadersAfter*Become* methods expect to be able to restore."
	<api>
	<var: #selector declareC: 'sqInt (*selector)(sqInt,sqInt,sqInt)'>
	| savedHeaderA savedHeaderB result |
	savedHeaderA := self baseHeader: obj1.
	self baseHeader: obj1 put: (self headerWhileForwardingOf: obj1).
	savedHeaderB := self baseHeader: obj2.
	self baseHeader: obj2 put: (self headerWhileForwardingOf: obj2).

	result := cogit perform: selector with: obj1 with: obj2 with: aBool.

	self baseHeader: obj1 put: savedHeaderA.
	self baseHeader: obj2 put: savedHeaderB.
	^result
]

{ #category : #'trampoline support' }
NewCoObjectMemory >> youngStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: youngStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #youngStart in: self]
]
