Class {
	#name : #InterpreterSimulatorMSB,
	#superclass : #InterpreterSimulator,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
InterpreterSimulatorMSB >> byteAt: byteAddress [
	| lowBits bpwMinus1 |
	bpwMinus1 := self wordSize-1.
	lowBits := byteAddress bitAnd: bpwMinus1.
	^ ((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - bpwMinus1) * 8)
		bitAnd: 16rFF
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> byteAt: byteAddress put: byte [
	| longWord shift lowBits bpwMinus1 longAddress |
	bpwMinus1 := self wordSize-1.
	lowBits := byteAddress bitAnd: bpwMinus1.
	longAddress := byteAddress - lowBits.
	longWord := self longAt: longAddress.
	shift := (bpwMinus1 - lowBits) * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFF bitShift: shift))
				+ (byte bitShift: shift).
	self longAt: longAddress put: longWord.
	^byte
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> byteSwapped32IfBigEndian: w [
	"Accelerate, we now we are big endian"
	^w byteSwap32
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> byteSwapped64IfBigEndian: w [
	"Accelerate, we now we are big endian"
	^w byteSwap64
]

{ #category : #'debug support' }
InterpreterSimulatorMSB >> charsOfLong: long [
	^ (self wordSize to: 1 by: -1) collect:
		[:i | ((long digitAt: i) between: 14 and: 126)
					ifTrue: [(long digitAt: i) asCharacter]
					ifFalse: [$?]]
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #initialization }
InterpreterSimulatorMSB >> nextLongFrom: aStream [ 
	"Read a 32- or 64-bit quantity from the given (binary) stream."

	^ aStream nextNumber: self wordSize
]

{ #category : #'image save/restore' }
InterpreterSimulatorMSB >> putLong: n toFile: f [
	"Append the given 4-byte long word to the given file in my byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails."

	f
		nextPut: (n bitShift: -24);
		nextPut: ((n bitShift: -16) bitAnd: 16rFF);
		nextPut: ((n bitShift: -8) bitAnd: 16rFF);
		nextPut: (n bitAnd: 16rFF).

	self success: true
]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits bpwMinus2 |
	bpwMinus2 := self wordSize-2.
	lowBits := byteAddress bitAnd: bpwMinus2.
	^ ((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - bpwMinus2) * 8)
		bitAnd: 16rFFFF

]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> shortAt: byteAddress put: a16BitValue [
    "Return the half-word at byteAddress which must be even."
	| longWord shift lowBits bpwMinus2 longAddress |
	bpwMinus2 := self wordSize-2.
	lowBits := byteAddress bitAnd: bpwMinus2.
	longAddress := byteAddress - lowBits.
	longWord := self longAt: longAddress.
	shift := (bpwMinus2 - lowBits) * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFFFF bitShift: shift))
				+ (a16BitValue bitShift: shift).
	self longAt: longAddress put: longWord

]

{ #category : #'memory access' }
InterpreterSimulatorMSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^1
]
