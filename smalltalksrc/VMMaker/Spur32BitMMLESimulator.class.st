Class {
	#name : #Spur32BitMMLESimulator,
	#superclass : #Spur32BitMemoryManager,
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #'become api' }
Spur32BitMMLESimulator >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag [

	"(thisContext findContextSuchThat: [:c| c selector == #rehashImage]) ifNotNil:
		[:ctxt|
		(((ctxt tempAt: 4) at: 1) = 108
		 and: [(ctxt tempAt: 2) byteCount = 553985]) ifTrue: [self halt]]."
	^super become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> booleanValueOf: obj [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter booleanValueOf: obj
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> byteAt: byteAddress [
	| lowBits long |
	lowBits := byteAddress bitAnd: 3.
	long := self longAt: byteAddress - lowBits.
	^(lowBits caseOf: {
		[0] -> [ long ].
		[1] -> [ long bitShift: -8  ].
		[2] -> [ long bitShift: -16 ].
		[3] -> [ long bitShift: -24 ]
	}) bitAnd: 16rFF
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> byteAt: byteAddress put: byte [
	| lowBits long longAddress |
	lowBits := byteAddress bitAnd: 3.
	longAddress := byteAddress - lowBits.
	long := self longAt: longAddress.
	long := (lowBits caseOf: {
		[0] -> [ (long bitAnd: 16rFFFFFF00) bitOr: byte ].
		[1] -> [ (long bitAnd: 16rFFFF00FF) bitOr: (byte bitShift: 8) ].
		[2] -> [ (long bitAnd: 16rFF00FFFF) bitOr: (byte bitShift: 16)  ].
		[3] -> [ (long bitAnd: 16r00FFFFFF) bitOr: (byte bitShift: 24)  ]
	}).
	self assert: (self cheapAddressCouldBeInHeap: longAddress).
	self longAt: longAddress put: long.
	^byte
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address."

	^self byteAt: pointer
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> cCoerce: value to: cTypeString [
	"Type coercion. For translation a cast will be emmitted. When running in Smalltalk
	 answer a suitable wrapper for correct indexing."

	^value
		ifNil: [value]
		ifNotNil: [value coerceTo: cTypeString sim: self]
]

{ #category : #'debug support' }
Spur32BitMMLESimulator >> eek [
	self halt
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> endianness [
	^#little
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> failed [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter failed
]

{ #category : #'float primitives' }
Spur32BitMMLESimulator >> fetchFloatAt: floatBitsAddress into: aFloat [
	aFloat at: 2 put: (self long32At: floatBitsAddress).
	aFloat at: 1 put: (self long32At: floatBitsAddress+4)
]

{ #category : #'object format' }
Spur32BitMMLESimulator >> firstIndexableField: objOop [
	"NOTE: overridden from SpurMemoryManager to add coercion to CArray, so please duplicate any changes.
	 There are only two important cases, both for objects with named inst vars, i.e. formats 2,3 & 5.
	 The first indexable field for formats 2 & 5 is the slot count (by convention, even though that's off the end
	 of the object).  For 3 we must go to the class."
	| fmt classFormat |
	<returnTypeC: #'void *'>
	fmt := self formatOf: objOop.
	fmt <= self lastPointerFormat ifTrue: "pointer; may need to delve into the class format word"
		[(fmt between: self indexablePointersFormat and: self weakArrayFormat) ifTrue:
			[classFormat := self formatOfClass: (self fetchClassOfNonImm: objOop).
			 ^self cCoerce: (self pointerForOop: objOop
												+ self baseHeaderSize
												+ ((self fixedFieldsOfClassFormat: classFormat) << self wordSize))
					to: #'oop *'].
		^self cCoerce: (self pointerForOop: objOop
											+ self baseHeaderSize
											+ ((self numSlotsOf: objOop) << self wordSize))
				to: #'oop *'].
	"All bit objects, and indeed CompiledMethod, though this is a non-no, start at 0"
	self assert: (fmt >= self sixtyFourBitIndexableFormat and: [fmt < self firstCompiledMethodFormat]).
	^self
		cCoerce: (self pointerForOop: objOop + self baseHeaderSize)
		to: (fmt < self firstByteFormat
				ifTrue:
					[fmt = self sixtyFourBitIndexableFormat
						ifTrue: ["64 bit field objects" #'long long *']
						ifFalse:
							[fmt < self firstShortFormat
								ifTrue: ["32 bit field objects" #'int *']
								ifFalse: ["16-bit field objects" #'short *']]]
				ifFalse: ["byte objects (including CompiledMethod" #'char *'])
]

{ #category : #become }
Spur32BitMMLESimulator >> forward: obj1 to: obj2 [
	"(obj1 = 16r150CD8 or: [obj1 = 16r1510B8
	 or: [obj2 = 16r150CD8 or: [obj2 = 16r1510B8]]]) ifTrue:
		[self halt]."
	^super forward: obj1 to: obj2
]

{ #category : #'header format' }
Spur32BitMMLESimulator >> headerForSlots: numSlots format: formatField classIndex: classIndex [
	"The header format in LSB is
	 MSB:	| 2 bits				|
			| 22: identityHash	|
			| 8: slotSize			|
			| 3 bits				|
			| 5: format			|
			| 2 bits				|
			| 22: classIndex		| : LSB"
	self assert: (numSlots bitAnd: self numSlotsMask) = numSlots.
	self assert: (formatField bitAnd: self formatMask) = formatField.
	self assert: (classIndex bitAnd: self classIndexMask) = classIndex.
	^super headerForSlots: numSlots format: formatField classIndex: classIndex
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> ioLoadFunction: functionString From: pluginString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter ioLoadFunction: functionString From: pluginString
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> is: oop KindOf: classNameString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter is: oop KindOf: classNameString
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> long32At: byteAddress [
	"Answer the 32-bit word at byteAddress which must be 0 mod 4."

	^self longAt: byteAddress
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	^self longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	"(byteAddress = 16r120DBDC and: [a32BitValue = 16r16000000]) ifTrue:
		[self halt]."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1 put: a32BitValue
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> longLongAt: byteAddress [
	"memory is a Bitmap, a 32-bit indexable array of bits"
	| hiWord loWord |
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	loWord := memory at: byteAddress // 4 + 1.
	hiWord := memory at: byteAddress // 4 + 2.
	^hiWord = 0
		ifTrue: [loWord]
		ifFalse: [(hiWord bitShift: 32) + loWord]
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> longLongAt: byteAddress put: a64BitValue [
	"memory is a Bitmap, a 32-bit indexable array of bits"
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	"((byteAddress = 16r120DBDC or: [byteAddress = 16r120DBD8])
	 and: [a64BitValue >> 32 = 16r16000000
		or: [(a64BitValue bitAnd: 16rffffffff) = 16r16000000]]) ifTrue:
			[self halt]."
	memory
		at: byteAddress // 4 + 1 put: (a64BitValue bitAnd: 16rffffffff);
		at: byteAddress // 4 + 2 put: a64BitValue >> 32.
	^a64BitValue
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> methodArgumentCount [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter methodArgumentCount
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> pop: nItems [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pop: nItems
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> pop: nItems thenPush: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pop: nItems thenPush: oop
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> pushBool: trueOrFalse [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter pushBool: trueOrFalse
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> stackValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter stackValue: offset
]

{ #category : #'float primitives' }
Spur32BitMMLESimulator >> storeFloatAt: floatBitsAddress from: aFloat [
	self long32At: floatBitsAddress put: (aFloat at: 2).
	self long32At: floatBitsAddress+4 put: (aFloat at: 1)
]

{ #category : #'simulation only' }
Spur32BitMMLESimulator >> success: boolean [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter success: boolean
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> unalignedAccessError [
	^self error: 'unaligned access'
]
