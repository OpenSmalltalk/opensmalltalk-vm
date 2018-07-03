Class {
	#name : #CoInterpreterStackPagesLSB,
	#superclass : #CoInterpreterStackPages,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'memory access' }
CoInterpreterStackPagesLSB >> byteAt: byteAddress [
	| lowBits long |
	lowBits := byteAddress bitAnd: objectMemory wordSize - 1.
	long := self longAt: byteAddress - lowBits.
	lowBits > 0 ifTrue:
		[long := long bitShift: lowBits * -8].
	^long bitAnd: 16rFF
]

{ #category : #'memory access' }
CoInterpreterStackPagesLSB >> byteAt: byteAddress put: byte [
	| lowBits long longAddress |
	self assert: (byte between: 0 and: 16rFF).
	lowBits := byteAddress bitAnd: objectMemory wordSize - 1.
	longAddress := byteAddress - lowBits.
	long := self longAt: longAddress.
	long := (long bitOr: (16rFF bitShift: lowBits * 8)) bitXor: (byte bitXor: 16rFF).
	self longAt: longAddress put: long.
	^byte
]
