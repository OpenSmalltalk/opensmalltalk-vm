"
I am a class that helps simulate the StackInterpreter's stack organization on big-endian platforms.
"
Class {
	#name : #InterpreterStackPagesMSB,
	#superclass : #InterpreterStackPages,
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'memory access' }
InterpreterStackPagesMSB >> byteAt: byteAddress [
	| lowBits bpwMinus1 |
	bpwMinus1 := StackInterpreter wordSize - 1.
	lowBits := byteAddress bitAnd: bpwMinus1.
	^((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - bpwMinus1) * 8)
		bitAnd: 16rFF
]
