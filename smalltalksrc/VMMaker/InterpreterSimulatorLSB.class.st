"
This class overrides a few methods in InterpreterSimulator required for simulation to work on little-endian architectures (such as the x86 family of processors).  To start it up simply use InterpreterSimulatorLSB instead of InterpreterSimulator (see the class comment there for more details).  For example:

	(InterpreterSimulatorLSB new openOn: Smalltalk imageName) test

Note that the image must have been saved at least once on the local architecture, since the compiled VM performs some byte swapping that the simulator cannot cope with.
"
Class {
	#name : #InterpreterSimulatorLSB,
	#superclass : #InterpreterSimulator,
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
InterpreterSimulatorLSB class >> new [
	^self basicNew
]

{ #category : #'memory access' }
InterpreterSimulatorLSB >> byteAt: byteAddress [
	| lowBits |
	lowBits _ byteAddress bitAnd: 3.
	^((self longAt: byteAddress - lowBits)
		bitShift: (0 - lowBits) * 8)
		bitAnd: 16rFF
]

{ #category : #'memory access' }
InterpreterSimulatorLSB >> byteAt: byteAddress put: byte [
	| longWord shift lowBits |
	lowBits _ byteAddress bitAnd: 3.
	longWord _ self longAt: byteAddress - lowBits.
	shift _ lowBits * 8.
	longWord _ longWord - (longWord bitAnd: (16rFF bitShift: shift)) + (byte bitShift: shift).
	self longAt: byteAddress - lowBits put: longWord
]

{ #category : #'debug support' }
InterpreterSimulatorLSB >> charsOfLong: long [
	^ (1 to: 4) collect:
		[:i | ((long digitAt: i) between: 14 and: 126)
					ifTrue: [(long digitAt: i) asCharacter]
					ifFalse: [$?]]
]

{ #category : #'debug support' }
InterpreterSimulatorLSB >> displayForm: f [
	| width height depth bits realForm simDisp realDisp |
	bits _ self fetchPointer: 0 ofObject: f.
	width _ self fetchInteger: 1 ofObject: f.
	height _ self fetchInteger: 2 ofObject: f.
	depth _ self fetchInteger: 3 ofObject: f.
	realForm _ Form extent: width@height depth: depth.
	simDisp _ Form new hackBits: memory.
	realDisp _ Form new hackBits: realForm bits.
	realDisp
		copy: (0 @ 0 extent: 4 @ realForm bits size)
		from: (0 @ (bits + 4 // 4))
		in: simDisp
		rule: Form over.
	realForm displayOn: Display at: 0@0.
]

{ #category : #initialization }
InterpreterSimulatorLSB >> nextLongFrom: aStream [
	"Read a 32-bit quantity from the given (binary) stream."
	| bytes |
	bytes _ aStream nextInto: (ByteArray new: 4).
	^ Integer
		byte1: (bytes at: 1)
		byte2: (bytes at: 2)
		byte3: (bytes at: 3)
		byte4: (bytes at: 4)
]

{ #category : #'image save/restore' }
InterpreterSimulatorLSB >> putLong: n toFile: f [
	"Append the given 4-byte long word to the given file in my byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails."

	| remainingValue |

	remainingValue _ n.
	4 timesRepeat: [
		f nextPut: (remainingValue bitAnd: 16rFF).
		remainingValue _ remainingValue bitShift: -8].

	self success: true
]
