"
A ProcessorSimulationTrap is an Error raised by CogProcessorAliens which allow the VMSimulator to fix the problem and resume execution.
I know where the problem occured (pc) and which instruction is next (nextpc), which field of the processor need be read/written and what type of memory access was the source of error.

I am created in #handleExecutionPrimitiveFailureIn:minimumAddress:readOnlyBelow: and associated methods. 
In the IA32 case, the type is managed by the OpcodeExecutionMap, using the first byte of the last instruction as index. 
In the ARM case, we need rely on a case statement, since no byte (sequence) is able to directly tell which type I am of.
"
Class {
	#name : #ProcessorSimulationTrap,
	#superclass : #Error,
	#instVars : [
		'pc',
		'nextpc',
		'address',
		'type',
		'registerAccessor'
	],
	#category : #'Cog-Processors'
}

{ #category : #debugger }
ProcessorSimulationTrap class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'instance creation' }
ProcessorSimulationTrap class >> pc: pc nextpc: nextpc address: address type: type [
	^self new
		pc: pc;
		nextpc: nextpc;
		address: address;
		type: type
]

{ #category : #'instance creation' }
ProcessorSimulationTrap class >> pc: pc nextpc: nextpc address: address type: type accessor: regAccessorMessage [
	^self new
		pc: pc;
		nextpc: nextpc;
		address: address;
		type: type;
		registerAccessor: regAccessorMessage
]

{ #category : #accessing }
ProcessorSimulationTrap >> address [
	"Answer the value of address"

	^ address
]

{ #category : #accessing }
ProcessorSimulationTrap >> address: anObject [
	"Set the value of address"

	address := anObject
]

{ #category : #accessing }
ProcessorSimulationTrap >> nextpc [
	"Answer the value of nextpc"

	^ nextpc
]

{ #category : #accessing }
ProcessorSimulationTrap >> nextpc: anObject [
	"Set the value of nextpc"

	nextpc := anObject
]

{ #category : #accessing }
ProcessorSimulationTrap >> pc [
	"Answer the value of pc"

	^ pc
]

{ #category : #accessing }
ProcessorSimulationTrap >> pc: anObject [
	"Set the value of pc"

	pc := anObject
]

{ #category : #printing }
ProcessorSimulationTrap >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' (pc: '; print: pc; nextPut: $/. pc printOn: aStream base: 16.
	aStream nextPutAll: ' nextpc: '; print: nextpc; nextPut: $/. nextpc printOn: aStream base: 16.
	aStream nextPutAll: ' address: '; print: address; nextPut: $/. address printOn: aStream base: 16.
	aStream nextPutAll: ' type: '; print: type.
	aStream nextPutAll: ' accessor: '; print: registerAccessor; nextPut: $)
]

{ #category : #accessing }
ProcessorSimulationTrap >> registerAccessor [
	"Answer the value of registerAccessor"

	^ registerAccessor
]

{ #category : #accessing }
ProcessorSimulationTrap >> registerAccessor: anObject [
	"Set the value of registerAccessor"

	registerAccessor := anObject
]

{ #category : #accessing }
ProcessorSimulationTrap >> type [
	"Answer the value of type"

	^ type
]

{ #category : #accessing }
ProcessorSimulationTrap >> type: anObject [
	"Set the value of type"

	type := anObject
]
