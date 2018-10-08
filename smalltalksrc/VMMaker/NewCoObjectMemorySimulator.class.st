Class {
	#name : #NewCoObjectMemorySimulator,
	#superclass : #NewCoObjectMemory,
	#instVars : [
		'parent'
	],
	#category : 'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
NewCoObjectMemorySimulator class >> new [
	^self == NewCoObjectMemorySimulator
		ifTrue: [SmalltalkImage current endianness == #big
				ifTrue: [NewCoObjectMemorySimulatorMSB new]
				ifFalse: [NewCoObjectMemorySimulatorLSB new]]
		ifFalse: [super new]
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator class >> vmProxyMajorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^CoInterpreter vmProxyMajorVersion
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator class >> vmProxyMinorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^CoInterpreter vmProxyMinorVersion
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> baseHeaderSize [
	^4
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> byteAt: byteAddress [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> byteAt: byteAddress put: byte [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byte is an 8-bit quantity."

	^ self byteAt: pointer
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> byteAtPointer: pointer put: byteValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byteValue is an 8-bit quantity."

	^ self byteAt: pointer  put: byteValue
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> bytesPerOop [
	^4
]

{ #category : #initialization }
NewCoObjectMemorySimulator >> coInterpreter: aCoInterpreter cogit: aCogit [
	coInterpreter := aCoInterpreter.
	cogit := aCogit
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> cogCodeBase [
	^Cogit guardPageSize
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> eek [
	self halt
]

{ #category : #'interpreter access' }
NewCoObjectMemorySimulator >> fetchPointer: fieldIndex ofObject: oop [
	"index by word size, and return a pointer as long as the word size"
	self assert: oop >= self startOfMemory.
	self assert: oop + self baseHeaderSize + (fieldIndex << self shiftForWord) < freeStart.
	^super fetchPointer: fieldIndex ofObject: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> firstIndexableField: oop [
	"NOTE: overridden from ObjectMemory to add coercion to CArray, so please duplicate any changes"
	| hdr fmt totalLength fixedFields |
	<returnTypeC: #'void *'>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	fmt <= 4 ifTrue: "<= 4 pointer"
		["pointer; may need to delve into the class format word"
		totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
		fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
		^self cCoerce: (self pointerForOop: oop + self baseHeaderSize + (fixedFields << self shiftForWord)) to: 'oop *'].
	^self
		cCoerce: (self pointerForOop: oop + self baseHeaderSize)
		to: (fmt < 8
				ifTrue: [fmt = 6
						ifTrue: ["32 bit field objects" 'int *']
						ifFalse: ["full word objects (bits)" 'oop *']]
				ifFalse: ["byte objects (including CompiledMethod" 'char *'])
]

{ #category : #'gc -- mark and sweep' }
NewCoObjectMemorySimulator >> fullGC [
	"If we're /not/ a clone, clone the VM and push it over the cliff.
	 If it survives, destroy the clone and continue.  We should be OK until next time."
	parent ifNil:
		[coInterpreter cr; print: 'GC number '; print: statFullGCs; tab; flush.
		 CloneOnGC ifTrue:
			[coInterpreter cloneSimulation objectMemory fullGC.
			 Smalltalk garbageCollect]].
	^super fullGC
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'debug support' }
NewCoObjectMemorySimulator >> heapMapAtWord: address [
	^heapMap heapMapAtWord: address asInteger
]

{ #category : #'gc -- mark and sweep' }
NewCoObjectMemorySimulator >> incrementalGC [
	"If we're /not/ a clone, clone the VM and push it over the cliff.
	 If it survives, destroy the clone and continue.  We should be OK until next time."
	(self leakCheckNewSpaceGC
	 and: [parent isNil]) ifTrue:
		[coInterpreter cr; print: 'Incremental GC number '; print: statIncrGCs; tab; flush.
		 CloneOnScavenge ifTrue:
			[coInterpreter cloneSimulation objectMemory incrementalGC.
			 Smalltalk garbageCollect]].
	^super incrementalGC
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1 put: a32BitValue
]

{ #category : #'debugging traps' }
NewCoObjectMemorySimulator >> noteAsRoot: oop headerLoc: headerLoc [
	"Trap attempts to make cog methods roots."
	self assert: oop >= self startOfMemory.
	^super noteAsRoot: oop headerLoc: headerLoc
]

{ #category : #testing }
NewCoObjectMemorySimulator >> objectBefore: addr [
	| oop prev |
	oop := self firstObject.
	[oop < freeStart] whileTrue:
		[prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop.
		oop >= addr ifTrue: [^ prev]].
	^0
]

{ #category : #accessing }
NewCoObjectMemorySimulator >> parent [

	^ parent
]

{ #category : #accessing }
NewCoObjectMemorySimulator >> parent: anObject [

	parent := anObject
]

{ #category : #'debug support' }
NewCoObjectMemorySimulator >> setUpForUseByFacade: aCurrentImageCoInterpreterFacade [
	"This is a noop"
	<doNotGenerate>
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> shortAt: byteAddress put: a16BitValue [
	^ self subclassResponsibility
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> sqGrowMemory: oldLimit By: delta [
	| newMemory |
	coInterpreter transcript show: 'grow memory from ', oldLimit printString, ' by ', delta printString; cr.
	memory size * 4 < (oldLimit + delta) ifTrue:
		[newMemory := (memory class new: oldLimit + delta + 3 // 4).
		 newMemory replaceFrom: 1 to: memory size with: memory startingAt: 1.
		 memory := newMemory].
	^memory size * 4
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> sqShrinkMemory: oldLimit By: delta [
	coInterpreter transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^oldLimit
]

{ #category : #'interpreter access' }
NewCoObjectMemorySimulator >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Override to ensure acess is within the heap, and within the object"
	| fmt hdr |
	self assert: oop >= self startOfMemory.
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	self assert: ((fmt <= 4 or: [fmt >= 12])
				and: [fieldIndex >= 0 and: [fieldIndex < (self lengthOf: oop baseHeader: hdr format: fmt)]]).
	self assert: oop + self baseHeaderSize + (fieldIndex << self shiftForWord) < freeStart.
	^super storePointer: fieldIndex ofObject: oop withValue: valuePointer
]

{ #category : #'interpreter access' }
NewCoObjectMemorySimulator >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	"Override to ensure acess is within the heap, and within the object"
	| fmt hdr |
	self assert: oop >= self startOfMemory.
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	self assert: ((fmt <= 4 or: [fmt >= 12])
				and: [fieldIndex >= 0 and: [fieldIndex < (self lengthOf: oop baseHeader: hdr format: fmt)]]).
	self assert: oop + self baseHeaderSize + (fieldIndex << self shiftForWord) < freeStart.
	^super storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer
]

{ #category : #'debug support' }
NewCoObjectMemorySimulator >> tenuringIncrementalGC [
	coInterpreter transcript cr; nextPutAll: 'tenuringIncrementalGC ('; print: coInterpreter byteCount; space; print: freeStart; nextPut: $); flush.
	^super tenuringIncrementalGC
]

{ #category : #testing }
NewCoObjectMemorySimulator >> validOop: oop [
	" Return true if oop appears to be valid "
	(oop bitAnd: 1) = 1 ifTrue: [^ true].  "Integer"
	(oop bitAnd: 3) = 0 ifFalse: [^ false].  "Uneven address"
	oop >= freeStart ifTrue: [^ false].  "Out of range"
	"could test if within the first large freeblock"
	(self longAt: oop) = 4 ifTrue: [^ false].
	(self headerType: oop) = 2 ifTrue: [^ false].	"Free object"
	^ true
]
