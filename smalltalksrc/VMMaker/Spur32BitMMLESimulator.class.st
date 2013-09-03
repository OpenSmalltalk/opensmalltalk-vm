Class {
	#name : #Spur32BitMMLESimulator,
	#superclass : #Spur32BitMemoryManager,
	#category : #'VMMaker-MemoryManagerSimulation'
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
Spur32BitMMLESimulator >> endianness [
	^#little
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
	self assert: (numSlots between: 0 and: self numSlotsMask).
	self assert: (formatField between: 0 and: 31).
	self assert: (classIndex between: 0 and: 16r3fffff).
	^super headerForSlots: numSlots format: formatField classIndex: classIndex
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

{ #category : #'memory access' }
Spur32BitMMLESimulator >> unalignedAccessError [
	^self error: 'unaligned access'
]
