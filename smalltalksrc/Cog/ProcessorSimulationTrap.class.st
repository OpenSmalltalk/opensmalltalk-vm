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
	aStream nextPutAll: ' (pc: '; print: pc.
	aStream nextPutAll: ' nextpc: '; print: nextpc.
	aStream nextPutAll: ' address: '; print: address.
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
