Class {
	#name : #NewObjectMemorySimulatorLSB,
	#superclass : #NewObjectMemorySimulator,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> byteAt: byteAddress [
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
NewObjectMemorySimulatorLSB >> byteAt: byteAddress put: byte [
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
	self assert: longAddress < freeStart.
	self longAt: longAddress put: long.
	^byte
]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> endianness [
	^#little
]

{ #category : #'float primitives' }
NewObjectMemorySimulatorLSB >> fetchFloatAt: floatBitsAddress into: aFloat [
	aFloat at: 2 put: (self long32At: floatBitsAddress).
	aFloat at: 1 put: (self long32At: floatBitsAddress+4)
]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> long64At: byteAddress [
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
NewObjectMemorySimulatorLSB >> long64At: byteAddress put: a64BitValue [
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	self
		longAt: byteAddress put: (a64BitValue bitAnd: 16rffffffff);
		longAt: byteAddress + 4 put: a64BitValue >> 32.
	^a64BitValue
]

{ #category : #initialization }
NewObjectMemorySimulatorLSB >> nextLongFrom: aStream [
	"Read a 32- or 64-bit quantity from the given (binary) stream."

	^ aStream nextLittleEndianNumber: self wordSize
]

{ #category : #initialization }
NewObjectMemorySimulatorLSB >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^aStream nextLittleEndianNumber: 2
]

{ #category : #initialization }
NewObjectMemorySimulatorLSB >> nextWord32From: aStream [
	"Read a 32-bit quantity from the given (binary) stream."

	^aStream nextLittleEndianNumber: 4
]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits long |
	lowBits := byteAddress bitAnd: 2.
	long := self longAt: byteAddress - lowBits.
	^ lowBits = 2
		ifTrue: [ long bitShift: -16 ]
		ifFalse: [ long bitAnd: 16rFFFF ].

]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> shortAt: byteAddress put: a16BitValue [
    "Return the half-word at byteAddress which must be even."
	| lowBits long longAddress |
	lowBits := byteAddress bitAnd: 2.
	lowBits = 0
		ifTrue:
		[ "storing into LS word"
		long := self longAt: byteAddress.
		self longAt: byteAddress
				put: ((long bitAnd: 16rFFFF0000) bitOr: a16BitValue)
		]
		ifFalse:
		[longAddress := byteAddress - 2.
		long := self longAt: longAddress.
		self longAt: longAddress
				put: ((long bitAnd: 16rFFFF) bitOr: (a16BitValue bitShift: 16))
		]
]

{ #category : #'float primitives' }
NewObjectMemorySimulatorLSB >> storeFloatAt: floatBitsAddress from: aFloat [

	self long32At: floatBitsAddress put: (aFloat at: 2).
	self long32At: floatBitsAddress+4 put: (aFloat at: 1)
]

{ #category : #'memory access' }
NewObjectMemorySimulatorLSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^0
]
