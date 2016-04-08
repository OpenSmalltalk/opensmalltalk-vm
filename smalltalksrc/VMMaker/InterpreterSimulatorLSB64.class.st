Class {
	#name : #InterpreterSimulatorLSB64,
	#superclass : #InterpreterSimulatorLSB,
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
InterpreterSimulatorLSB64 >> long32At: byteAddress [

	"Return the 32-bit word at byteAddress which must be 0 mod 4."
	| lowBits long |
	lowBits := byteAddress bitAnd: 4.
	long := self longAt: byteAddress - lowBits.
	^ lowBits = 4
		ifTrue: [ long bitShift: -32 ]
		ifFalse: [ long bitAnd: 16rFFFFFFFF ].

]

{ #category : #'memory access' }
InterpreterSimulatorLSB64 >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."
	| lowBits long64 longAddress |
	lowBits := byteAddress bitAnd: 4.
	lowBits = 0
		ifTrue:
		[ "storing into LS word"
		long64 := self longAt: byteAddress.
		self longAt: byteAddress
				put: ((long64 bitAnd: 16rFFFFFFFF00000000) bitOr: a32BitValue)
		]
		ifFalse:
		[longAddress := byteAddress - 4.
		long64 := self longAt: longAddress.
		self longAt: longAddress
				put: ((long64 bitAnd: 16rFFFFFFFF) bitOr: (a32BitValue bitShift: 32))
		]
]

{ #category : #'memory access' }
InterpreterSimulatorLSB64 >> wordSize [
	"overridden for 64-bit images..."

	^8
]
