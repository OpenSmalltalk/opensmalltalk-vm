Class {
	#name : #InterpreterSimulatorMSB,
	#superclass : #InterpreterSimulator,
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
InterpreterSimulatorMSB >> byteAt: byteAddress [
	| lowBits |
	lowBits _ byteAddress bitAnd: 3.
	^((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - 3) * 8)
		bitAnd: 16rFF
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> byteAt: byteAddress put: byte [
	| longWord shift lowBits |
	lowBits _ byteAddress bitAnd: 3.
	longWord _ self longAt: byteAddress - lowBits.
	shift _ (3 - lowBits) * 8.
	longWord _ longWord - (longWord bitAnd: (16rFF bitShift: shift)) + (byte bitShift: shift).
	self longAt: byteAddress put: longWord
]

{ #category : #'debug support' }
InterpreterSimulatorMSB >> charsOfLong: long [
	^ (4 to: 1 by: -1) collect:
		[:i | ((long digitAt: i) between: 14 and: 126)
					ifTrue: [(long digitAt: i) asCharacter]
					ifFalse: [$?]]
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> halfWordAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits |
	lowBits _ byteAddress bitAnd: 2.
	^((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - 2) * 8)
		bitAnd: 16rFFFF

]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> halfWordAt: byteAddress put: halfWord [
	| longWord shift lowBits |
	lowBits _ byteAddress bitAnd: 2.
	longWord _ self longAt: byteAddress - lowBits.
	shift _ lowBits * 8.
	longWord _ longWord - (longWord bitAnd: (16rFFFF bitShift: shift)) +
(halfWord bitShift: shift).
	self longAt: byteAddress - lowBits put: longWord

]

{ #category : #initialization }
InterpreterSimulatorMSB >> nextLongFrom: aStream [ 
	"Read a 32-bit quantity from the given (binary) stream."
	| bytes |
	bytes _ aStream nextInto: (ByteArray new: 4).
	^ Integer
		byte1: (bytes at: 4)
		byte2: (bytes at: 3)
		byte3: (bytes at: 2)
		byte4: (bytes at: 1)
]

{ #category : #'image save/restore' }
InterpreterSimulatorMSB >> putLong: n toFile: f [
	"Append the given 4-byte long word to the given file in my byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails."

	f
		nextPut: (n bitShift: -24);
		nextPut: ((n bitAnd: 16rFF0000) bitShift: -16);
		nextPut: ((n bitAnd: 16rFF00) bitShift: -8);
		nextPut: (n bitAnd: 16rFF).

	self success: true
]
