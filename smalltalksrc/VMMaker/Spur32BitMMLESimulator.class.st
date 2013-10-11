Class {
	#name : #Spur32BitMMLESimulator,
	#superclass : #Spur32BitMemoryManager,
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

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
	self longAt: longAddress put: long.
	^byte
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address."

	^self byteAt: pointer
]

{ #category : #'debug support' }
Spur32BitMMLESimulator >> eek [
	self halt
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> endianness [
	^#little
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

{ #category : #'spur bootstrap' }
Spur32BitMMLESimulator >> freeLists [
	^freeLists
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^long32 bitShift: -16
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

{ #category : #'memory access' }
Spur32BitMMLESimulator >> intAt: byteAddress put: a32BitValue [
	^self longAt: byteAddress put: (a32BitValue bitAnd: 16rFFFFFFFF)
]

{ #category : #'object testing' }
Spur32BitMMLESimulator >> isIntegerObject: oop [
	"This list records the valid senders of isIntegerObject: as we replace uses of
	  isIntegerObject: by isImmediate: where appropriate."
	| sel |
	sel := thisContext sender method selector.
	(#(	DoIt
		DoItIn:
		on:do: "from the debugger"
		makeBaseFrameFor:
		quickFetchInteger:ofObject:
		frameOfMarriedContext:
		objCouldBeClassObj:
		isMarriedOrWidowedContext:
		shortPrint:
		bytecodePrimAt
		bytecodePrimAtPut
		commonAt:
		commonAtPut:
		loadFloatOrIntFrom:
		positive32BitValueOf:
		primitiveExternalCall
		checkedIntegerValueOf:
		bytecodePrimAtPut
		commonAtPut:
		primitiveVMParameter
		checkIsStillMarriedContext:currentFP:
		displayBitsOf:Left:Top:Right:Bottom:
		fetchStackPointerOf:
		primitiveContextAt
		primitiveContextAtPut
		subscript:with:storing:format:
		printContext:
		compare31or32Bits:equal:
		signed64BitValueOf:
		primDigitMultiply:negative:
		digitLength:
		isNegativeIntegerValueOf:
		magnitude64BitValueOf:
		primitiveMakePoint
		primitiveAsCharacter
		primitiveInputSemaphore
		baseFrameReturn
		primitiveExternalCall
		primDigitCompare:
		isLiveContext:
		numPointerSlotsOf:
		fileValueOf:
		loadBitBltDestForm
		fetchIntOrFloat:ofObject:ifNil:
		fetchIntOrFloat:ofObject:
		loadBitBltSourceForm
		loadPoint:from:
		primDigitAdd:
		primDigitSubtract:
		positive64BitValueOf:
		digitBitLogic:with:opIndex:
		signed32BitValueOf:
		isNormalized:
		primDigitDiv:negative:
		bytesOrInt:growTo:
		primitiveNewMethod
		isCogMethodReference:
		functionForPrimitiveExternalCall:
		genSpecialSelectorArithmetic
		genSpecialSelectorComparison
		ensureContextHasBytecodePC:
		instVar:ofContext:
		ceBaseFrameReturn:
		inlineCacheTagForInstance:
		primitiveObjectAtPut
		commonVariable:at:put:cacheIndex:
		primDigitBitShiftMagnitude:
		externalInstVar:ofContext:) includes: sel) ifFalse:
		[self halt].
	^super isIntegerObject: oop
]

{ #category : #'object testing' }
Spur32BitMMLESimulator >> isNonIntegerObject: oop [
	"This list records the valid senders of isNonIntegerObject: as we replace uses of
	  isNonIntegerObject: by isNonImmediate: where appropriate."
	(#(	on:do: "from the dbeugger"
		reverseDisplayFrom:to:
		primitiveObjectAtPut
		isCogMethodReference:) includes: thisContext sender method selector) ifFalse:
		[self halt].
	^super isNonIntegerObject: oop
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
	"(byteAddress = 16r1614CB8 and: [a32BitValue = 16rA000035]) ifTrue:
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
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	self
		longAt: byteAddress put: (a64BitValue bitAnd: 16rffffffff);
		longAt: byteAddress + 4 put: a64BitValue >> 32.
	^a64BitValue
]

{ #category : #'generation scavenging' }
Spur32BitMMLESimulator >> scavengingGCTenuringIf: tenuringCriterion [
	"Run the scavenger."
	"self halt: (statScavenges + 1) printString, ((statScavenges between: 9 and: 19)
													ifTrue: ['th']
													ifFalse: [#('st' 'nd' 'rd') at: (statScavenges + 1) \\ 10 ifAbsent: 'th']), ' scavenge'."
	^super scavengingGCTenuringIf: tenuringCriterion
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits long |
	lowBits := byteAddress bitAnd: 2.
	long := self longAt: byteAddress - lowBits.
	^ lowBits = 2
		ifTrue: [ long bitShift: -16 ]
		ifFalse: [ long bitAnd: 16rFFFF ]
]

{ #category : #'float primitives' }
Spur32BitMMLESimulator >> storeFloatAt: floatBitsAddress from: aFloat [
	self long32At: floatBitsAddress put: (aFloat at: 2).
	self long32At: floatBitsAddress+4 put: (aFloat at: 1)
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> vmEndianness [
	"1 = big, 0 = little"
	^0
]
