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
Spur32BitMMLESimulator >> endianness [
	^#little
]

{ #category : #'as yet unclassified' }
Spur32BitMMLESimulator >> fetchFloatAt: floatBitsAddress into: aFloat [
	aFloat at: 2 put: (self long32At: floatBitsAddress).
	aFloat at: 1 put: (self long32At: floatBitsAddress+4)
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
	memory
		at: byteAddress // 4 + 1 put: (a64BitValue bitAnd: 16rffffffff);
		at: byteAddress // 4 + 2 put: a64BitValue >> 32.
	^a64BitValue
]

{ #category : #'as yet unclassified' }
Spur32BitMMLESimulator >> storeFloatAt: floatBitsAddress from: aFloat [
	self long32At: floatBitsAddress put: (aFloat at: 2).
	self long32At: floatBitsAddress+4 put: (aFloat at: 1)
]

{ #category : #'memory access' }
Spur32BitMMLESimulator >> unalignedAccessError [
	^self error: 'unaligned access'
]
