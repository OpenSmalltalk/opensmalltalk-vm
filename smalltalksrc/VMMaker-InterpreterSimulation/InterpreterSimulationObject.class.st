Class {
	#name : #InterpreterSimulationObject,
	#superclass : #Object,
	#category : #'VMMaker-Plugins'
}

{ #category : #simulation }
InterpreterSimulationObject >> cCoerce: value to: cTypeString [
	"Here the Simulator has a chance to create properly typed flavors of CArray access."

	value isCObjectAccessor ifTrue:
		[^ self getInterpreter cCoerce: value to: cTypeString].
	(value isMemberOf: CArray) ifTrue:
		[^ self getInterpreter cCoerce: value to: cTypeString].
	^ value
]

{ #category : #'memory access' }
InterpreterSimulationObject >> long32At: byteAddress [
	"Simulation support.  Answer the 32-bit word at byteAddress which must be 0 mod 4."

	^self getInterpreter long32At: byteAddress
]

{ #category : #'memory access' }
InterpreterSimulationObject >> long32At: byteAddress put: a32BitValue [
	"Simulation support.  Store the 32-bit value at byteAddress which must be 0 mod 4."

	^self getInterpreter long32At: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
InterpreterSimulationObject >> oopForPointer: aPointer [
	"Simulation support.  Pointers and oops are the same when simulating; answer aPointer."

	^aPointer
]

{ #category : #'memory access' }
InterpreterSimulationObject >> pointerForOop: anOop [
	"Simulation support.  Pointers and oops are the same when simulating; answer anOop."

	^anOop
]
