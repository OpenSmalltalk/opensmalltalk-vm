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

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> arrayValueOf: arrayOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter arrayValueOf: arrayOop
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> baseHeaderSize [
	^4
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> booleanValueOf: obj [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter booleanValueOf: obj
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

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value == nil
		ifTrue: [value]
		ifFalse: [value coerceTo: cTypeString sim: self]
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> capturePendingFinalizationSignals [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter capturePendingFinalizationSignals
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> checkedIntegerValueOf: intOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter checkedIntegerValueOf: intOop
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

{ #category : #printing }
NewCoObjectMemorySimulator >> cr [
	^coInterpreter cr
]

{ #category : #'memory access' }
NewCoObjectMemorySimulator >> eek [
	self halt
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> failed [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter failed
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> fetchInteger: fieldIndex ofObject: objectPointer [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter fetchInteger: fieldIndex ofObject: objectPointer
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
		 coInterpreter cloneSimulation objectMemory fullGC.
		 Smalltalk garbageCollect].
	^super fullGC
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> getThisSessionID [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter getThisSessionID
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
		 coInterpreter cloneSimulation objectMemory incrementalGC.
		 Smalltalk garbageCollect].
	^super incrementalGC
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> interpreterAllocationReserveBytes [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter interpreterAllocationReserveBytes
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> ioLoadFunction: functionString From: pluginString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter ioLoadFunction: functionString From: pluginString
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> ioMicroMSecs [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter ioMicroMSecs
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> ioUTCMicrosecondsNow [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter ioUTCMicrosecondsNow
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> is: oop KindOf: classNameString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter is: oop KindOf: classNameString
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> isFloatObject: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter isFloatObject: oop
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

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> mapInterpreterOops [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter mapInterpreterOops
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> markAndTraceAndMaybeFreeStackPages: fullGCFlag [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter markAndTraceAndMaybeFreeStackPages: fullGCFlag
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> markAndTraceInterpreterOops: fullGCFlag [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter markAndTraceInterpreterOops: fullGCFlag
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> markAndTraceOrFreeMachineCode: fullGCFlag [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter markAndTraceOrFreeMachineCode: fullGCFlag
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> methodArgumentCount [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter methodArgumentCount
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> methodReturnValue: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter methodReturnValue: oop
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

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> pop: nItems [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pop: nItems
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> pop: nItems thenPush: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pop: nItems thenPush: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> positive32BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter positive32BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> positive32BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter positive32BitValueOf: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> positive64BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter positive64BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> positive64BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter positive64BitValueOf: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> postGCAction: gcMode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter postGCAction: gcMode
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> preGCAction: gcMode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter preGCAction: gcMode
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> primitiveFail [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter primitiveFail
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> primitiveFailFor: reasonCode [
	^coInterpreter primitiveFailFor: reasonCode
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> primitiveFailureCode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter primitiveFailureCode
]

{ #category : #printing }
NewCoObjectMemorySimulator >> print: thing [ 
	coInterpreter print: thing
]

{ #category : #printing }
NewCoObjectMemorySimulator >> printChar: aCharacter [
	coInterpreter printChar: aCharacter 
]

{ #category : #printing }
NewCoObjectMemorySimulator >> printHex: n [
	coInterpreter printHex: n 
]

{ #category : #printing }
NewCoObjectMemorySimulator >> printHexPtr: address [
	coInterpreter printHexPtr: address
]

{ #category : #printing }
NewCoObjectMemorySimulator >> printNum: n [
	coInterpreter printNum: n
]

{ #category : #printing }
NewCoObjectMemorySimulator >> printOop: anOop [ 
	coInterpreter printOop: anOop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> push: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter push: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> pushBool: trueOrFalse [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pushBool: trueOrFalse
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> pushFloat: f [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pushFloat: f
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> pushInteger: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pushInteger: integerValue
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

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter showDisplayBits: aForm Left: l Top: t Right: r Bottom: b
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> signalFinalization: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter signalFinalization: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> signed32BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter signed32BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> signed32BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter signed32BitValueOf: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> signedMachineIntegerValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter signedMachineIntegerValueOf: oop
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

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stObject: objOop at: indexOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stObject: objOop at: indexOop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stObject: objOop at: indexOop put: valueOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stObject: objOop at: indexOop put: valueOop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stackFloatValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stackFloatValue: offset
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stackIntegerValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stackIntegerValue: offset
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stackObjectValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stackObjectValue: offset
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stackValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stackValue: offset
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue
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

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> stringOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stringOf: oop
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> success: boolean [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter success: boolean
]

{ #category : #printing }
NewCoObjectMemorySimulator >> tab [
	coInterpreter tab
]

{ #category : #'debug support' }
NewCoObjectMemorySimulator >> tenuringIncrementalGC [
	coInterpreter transcript cr; nextPutAll: 'tenuringIncrementalGC ('; print: coInterpreter byteCount; space; print: freeStart; nextPut: $); flush.
	^super tenuringIncrementalGC
]

{ #category : #'simulation only' }
NewCoObjectMemorySimulator >> transcript [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter transcript
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
