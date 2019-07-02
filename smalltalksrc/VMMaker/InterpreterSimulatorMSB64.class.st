Class {
	#name : #InterpreterSimulatorMSB64,
	#superclass : #InterpreterSimulatorMSB,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
InterpreterSimulatorMSB64 >> byteSwapped: w [
	"Return the given integer with its bytes in the reverse order."

	^w byteSwap64
]

{ #category : #'memory access' }
InterpreterSimulatorMSB64 >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."

	^ super longAt: byteAddress
]

{ #category : #'memory access' }
InterpreterSimulatorMSB64 >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	super longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
InterpreterSimulatorMSB64 >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^ ((super longAt: byteAddress) bitShift: 32) bitOr: (super longAt: byteAddress + 4)
]

{ #category : #'memory access' }
InterpreterSimulatorMSB64 >> longAt: byteAddress put: a64BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	super longAt: byteAddress put: (a64BitValue bitShift: -32).
	super longAt: byteAddress + 4 put: (a64BitValue bitAnd: 16rFFFFFFFF).
	^ a64BitValue
]

{ #category : #'memory access' }
InterpreterSimulatorMSB64 >> wordSize [
	"overridden for 64-bit images..."

	^8
]
