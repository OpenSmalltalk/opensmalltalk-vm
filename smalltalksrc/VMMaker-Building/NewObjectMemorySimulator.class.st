Class {
	#name : #NewObjectMemorySimulator,
	#superclass : #NewObjectMemory,
	#instVars : [
		'parent'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
NewObjectMemorySimulator class >> new [
	^self == NewObjectMemorySimulator
		ifTrue: [SmalltalkImage current endianness == #big
				ifTrue: [NewObjectMemorySimulatorMSB new]
				ifFalse: [NewObjectMemorySimulatorLSB new]]
		ifFalse: [super new]
]

{ #category : #'simulation only' }
NewObjectMemorySimulator class >> vmProxyMajorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMajorVersion
]

{ #category : #'simulation only' }
NewObjectMemorySimulator class >> vmProxyMinorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMinorVersion
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> baseHeaderSize [
	^4
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> byteAt: byteAddress [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> byteAt: byteAddress put: byte [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byte is an 8-bit quantity."

	^ self byteAt: pointer
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> byteAtPointer: pointer put: byteValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byteValue is an 8-bit quantity."

	^ self byteAt: pointer  put: byteValue
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> bytesPerOop [
	^4
]

{ #category : #initialization }
NewObjectMemorySimulator >> coInterpreter: aCoInterpreter [
	coInterpreter := aCoInterpreter
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> eek [
	self halt
]

{ #category : #'simulation only' }
NewObjectMemorySimulator >> firstIndexableField: oop [
	"NOTE: overridden from ObjectMemory to add coercion to CArray, so please duplicate any changes"
	| hdr fmt totalLength fixedFields |
	<returnTypeC: #'void *'>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	fmt <= self lastPointerFormat ifTrue:
		["pointer; may need to delve into the class format word"
		totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
		fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
		^self cCoerce: (self pointerForOop: oop + self baseHeaderSize + (fixedFields << self shiftForWord)) to: 'oop *'].
	^self
		cCoerce: (self pointerForOop: oop + self baseHeaderSize)
		to: (fmt < self firstByteFormat
				ifTrue: [fmt = self firstLongFormat
						ifTrue: ["32 bit field objects" 'int *']
						ifFalse: ["full word objects (bits)" 'oop *']]
				ifFalse: ["byte objects (including CompiledMethod" 'char *'])
]

{ #category : #'gc -- mark and sweep' }
NewObjectMemorySimulator >> fullGC [
	"If we're /not/ a clone, clone the VM and push it over the cliff.
	 If it survives, destroy the clone and continue.  We should be OK until next time."
	parent ifNil:
		[coInterpreter cr; print: 'GC number '; print: statFullGCs; tab; flush.
		 CloneOnGC ifTrue:
			[coInterpreter cloneSimulation objectMemory fullGC.
			 Smalltalk garbageCollect]].
	^super fullGC
]

{ #category : #'interpreter access' }
NewObjectMemorySimulator >> getStackPointer [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter getStackPointer
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'gc -- mark and sweep' }
NewObjectMemorySimulator >> incrementalGC [
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
NewObjectMemorySimulator >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1 put: a32BitValue
]

{ #category : #'image save/restore' }
NewObjectMemorySimulator >> memoryBaseForImageRead [
	"Answer the address to read the image into."
	^0
]

{ #category : #testing }
NewObjectMemorySimulator >> objectBefore: addr [
	| oop prev |
	oop := self firstObject.
	[oop < freeStart] whileTrue:
		[prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop.
		oop >= addr ifTrue: [^ prev]].
	^0
]

{ #category : #accessing }
NewObjectMemorySimulator >> parent [

	^ parent
]

{ #category : #accessing }
NewObjectMemorySimulator >> parent: anObject [

	parent := anObject
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> shortAt: byteAddress put: a16BitValue [
	^ self subclassResponsibility
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> sqGrowMemory: oldLimit By: delta [
	| newMemory |
	coInterpreter transcript show: 'grow memory from ', oldLimit printString, ' by ', delta printString; cr.
	memory size * 4 < (oldLimit + delta) ifTrue:
		[newMemory := (memory class new: oldLimit + delta + 3 // 4).
		 newMemory replaceFrom: 1 to: memory size with: memory startingAt: 1.
		 memory := newMemory].
	^memory size * 4
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
NewObjectMemorySimulator >> sqShrinkMemory: oldLimit By: delta [
	coInterpreter transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^oldLimit
]

{ #category : #initialization }
NewObjectMemorySimulator >> startOfMemory [
	"Return the start of object memory."

	^ 0
]

{ #category : #'interpreter access' }
NewObjectMemorySimulator >> storePointer: index ofObject: oop withValue: valuePointer [
	"Override to ensure acess is within the heap, and within the object"
	| fmt hdr |
	self assert: oop >= self startOfMemory.
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	self assert: ((fmt <= self lastPointerFormat or: [fmt >= self firstCompiledMethodFormat])
				and: [index >= 0 and: [index < (self lengthOf: oop baseHeader: hdr format: fmt)]]).
	^super storePointer: index ofObject: oop withValue: valuePointer
]

{ #category : #'interpreter access' }
NewObjectMemorySimulator >> storePointerUnchecked: index ofObject: oop withValue: valuePointer [
	"Override to ensure acess is within the heap, and within the object"
	| fmt hdr |
	self assert: oop >= self startOfMemory.
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	self assert: ((fmt <= self lastPointerFormat or: [fmt >= self firstCompiledMethodFormat])
				and: [index >= 0 and: [index < (self lengthOf: oop baseHeader: hdr format: fmt)]]).
	^super storePointerUnchecked: index ofObject: oop withValue: valuePointer
]

{ #category : #'debug support' }
NewObjectMemorySimulator >> tenuringIncrementalGC [
	coInterpreter transcript cr; nextPutAll: 'tenuringIncrementalGC ('; print: coInterpreter byteCount; space; print: freeStart; nextPut: $); flush.
	^super tenuringIncrementalGC
]

{ #category : #testing }
NewObjectMemorySimulator >> validOop: oop [
	" Return true if oop appears to be valid "
	(oop bitAnd: 1) = 1 ifTrue: [^ true].  "Integer"
	(oop bitAnd: 3) = 0 ifFalse: [^ false].  "Uneven address"
	oop >= freeStart ifTrue: [^ false].  "Out of range"
	"could test if within the first large freeblock"
	(self longAt: oop) = 4 ifTrue: [^ false].
	(self headerType: oop) = 2 ifTrue: [^ false].	"Free object"
	^ true
]
