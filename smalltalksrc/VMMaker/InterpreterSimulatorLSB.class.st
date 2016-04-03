"
This class overrides a few methods in InterpreterSimulator required for simulation to work on little-endian architectures (such as the x86 family of processors).  To start it up simply use InterpreterSimulatorLSB instead of InterpreterSimulator (see the class comment there for more details).  For example:

	(InterpreterSimulatorLSB new openOn: Smalltalk imageName) test

Note that the image must have been saved at least once on the local architecture, since the compiled VM performs some byte swapping that the simulator cannot cope with.
"
Class {
	#name : #InterpreterSimulatorLSB,
	#superclass : #InterpreterSimulator,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
InterpreterSimulatorLSB >> byteAt: byteAddress [
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
InterpreterSimulatorLSB >> byteAt: byteAddress put: byte [
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
InterpreterSimulatorLSB >> charsOfLong: long [
	^ (1 to: 4) collect:
		[:i | ((long digitAt: i) between: 14 and: 126)
					ifTrue: [(long digitAt: i) asCharacter]
					ifFalse: [$?]]
]

{ #category : #'memory access' }
InterpreterSimulatorLSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
InterpreterSimulatorLSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #initialization }
InterpreterSimulatorLSB >> nextLongFrom: aStream [
	"Read a 32- or 64-bit quantity from the given (binary) stream."

	^ aStream nextLittleEndianNumber: self wordSize
]

{ #category : #'image save/restore' }
InterpreterSimulatorLSB >> putLong: n toFile: f [
	"Append the given 4-byte long word to the given file in my byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails."

	| remainingValue |

	remainingValue := n.
	4 timesRepeat: [
		f nextPut: (remainingValue bitAnd: 16rFF).
		remainingValue := remainingValue bitShift: -8].

	self success: true
]

{ #category : #'memory access' }
InterpreterSimulatorLSB >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits long |
	lowBits := byteAddress bitAnd: 2.
	long := self longAt: byteAddress - lowBits.
	^ lowBits = 2
		ifTrue: [ long bitShift: -16 ]
		ifFalse: [ long bitAnd: 16rFFFF ].

]

{ #category : #'memory access' }
InterpreterSimulatorLSB >> shortAt: byteAddress put: a16BitValue [
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

{ #category : #'memory access' }
InterpreterSimulatorLSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^0
]
