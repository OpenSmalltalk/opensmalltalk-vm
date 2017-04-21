"
This class overrides a few methods in StackInterpreterSimulator required for simulation to work on little-endian architectures (such as the x86 family of processors).  To start it up simply use StackInterpreterSimulatorLSB instead of StackInterpreterSimulator (see the class comment there for more details).  For example:

	(StackInterpreterSimulatorLSB new openOn: Smalltalk imageName) test

Note that the image must have been saved at least once on the local architecture, since the compiled VM performs some byte swapping that the simulator cannot cope with.
"
Class {
	#name : #StackInterpreterSimulatorLSB,
	#superclass : #StackInterpreterSimulator,
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'debug support' }
StackInterpreterSimulatorLSB >> charsOfLong: long [
	^ (1 to: objectMemory wordSize) collect:
		[:i | ((long digitAt: i) between: 14 and: 126)
					ifTrue: [(long digitAt: i) asCharacter]
					ifFalse: [$?]]
]

{ #category : #'memory access' }
StackInterpreterSimulatorLSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
StackInterpreterSimulatorLSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #initialization }
StackInterpreterSimulatorLSB >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^aStream nextLittleEndianNumber: 2
]

{ #category : #'memory access' }
StackInterpreterSimulatorLSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^0
]
