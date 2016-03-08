Class {
	#name : #CoInterpreterStackPagesMSB,
	#superclass : #CoInterpreterStackPages,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #'memory access' }
CoInterpreterStackPagesMSB >> byteAt: byteAddress [
	| lowBits bpwMinus1 |
	bpwMinus1 := objectMemory wordSize - 1.
	lowBits := byteAddress bitAnd: bpwMinus1.
	^((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - bpwMinus1) * 8)
		bitAnd: 16rFF
]
