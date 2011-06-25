Class {
	#name : #NewCoObjectMemorySimulatorLSB,
	#superclass : #NewCoObjectMemorySimulator,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> byteAt: byteAddress [
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
NewCoObjectMemorySimulatorLSB >> byteAt: byteAddress put: byte [
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

{ #category : #'debug support' }
NewCoObjectMemorySimulatorLSB >> charsOfLong: long [
	^ (1 to: 4) collect:
		[:i | ((long digitAt: i) between: 14 and: 126)
					ifTrue: [(long digitAt: i) asCharacter]
					ifFalse: [$?]]
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> endianness [
	^#little
]

{ #category : #'float primitives' }
NewCoObjectMemorySimulatorLSB >> fetchFloatAt: floatBitsAddress into: aFloat [
	aFloat at: 2 put: (self long32At: floatBitsAddress).
	aFloat at: 1 put: (self long32At: floatBitsAddress+4)
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #initialization }
NewCoObjectMemorySimulatorLSB >> nextLongFrom: aStream [
	"Read a 32- or 64-bit quantity from the given (binary) stream."

	^ aStream nextLittleEndianNumber: BytesPerWord
]

{ #category : #initialization }
NewCoObjectMemorySimulatorLSB >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^aStream nextLittleEndianNumber: 2
]

{ #category : #'image save/restore' }
NewCoObjectMemorySimulatorLSB >> putLong: n toFile: f [
	"Append the given 4-byte long word to the given file in my byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails."

	| remainingValue |

	remainingValue := n.
	4 timesRepeat: [
		f nextPut: (remainingValue bitAnd: 16rFF).
		remainingValue := remainingValue bitShift: -8].

	self success: true
]

{ #category : #'image save/restore' }
NewCoObjectMemorySimulatorLSB >> putShort: n toFile: f [
	"Append the given 2-byte half-word to the given file in my byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails."

	| remainingValue |

	remainingValue := n.
	2 timesRepeat: [
		f nextPut: (remainingValue bitAnd: 16rFF).
		remainingValue := remainingValue bitShift: -8].

	self success: true
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits long |
	lowBits := byteAddress bitAnd: 2.
	long := self longAt: byteAddress - lowBits.
	^ lowBits = 2
		ifTrue: [ long bitShift: -16 ]
		ifFalse: [ long bitAnd: 16rFFFF ].

]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> shortAt: byteAddress put: a16BitValue [
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
NewCoObjectMemorySimulatorLSB >> storeFloatAt: floatBitsAddress from: aFloat [

	self long32At: floatBitsAddress put: (aFloat at: 2).
	self long32At: floatBitsAddress+4 put: (aFloat at: 1)
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> unalignedLongAt: byteAddress [
	| rem |
	rem := byteAddress \\ 4.
	^rem = 0
		ifTrue: [self longAt: byteAddress]
		ifFalse: [((self longAt: byteAddress - rem) + ((self longAt: byteAddress - rem + 4) bitShift: 32) bitShift: rem * -8) bitAnd: 16rFFFFFFFF]
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> unalignedLongAt: byteAddress put: aLong [
	| rem mask |
	rem := byteAddress \\ 4.
	^rem = 0
		ifTrue: [self longAt: byteAddress put: aLong]
		ifFalse:
			[mask := 16rFFFFFFFF bitAnd: (-1 bitShift: rem * 8).
			 self longAt: byteAddress - rem
				put: ((self longAt: byteAddress - rem) bitAnd: mask bitInvert)
					+ ((aLong bitShift: rem * 8) bitAnd: mask).
			 self longAt: byteAddress - rem + 4
				put: ((self longAt: byteAddress - rem + 4) bitAnd: mask)
					+ ((aLong bitShift: 4 - rem * -8) bitAnd: mask bitInvert).
			 aLong]
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorLSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^0
]
