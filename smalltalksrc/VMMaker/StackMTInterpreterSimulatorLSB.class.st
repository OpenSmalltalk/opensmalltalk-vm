Class {
	#name : #StackMTInterpreterSimulatorLSB,
	#superclass : #StackMTInterpreterSimulator,
	#category : #'VMMaker-Multithreading'
}

{ #category : #'memory access' }
StackMTInterpreterSimulatorLSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
StackMTInterpreterSimulatorLSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #initialization }
StackMTInterpreterSimulatorLSB >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^aStream nextLittleEndianNumber: 2
]

{ #category : #'memory access' }
StackMTInterpreterSimulatorLSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^0
]
