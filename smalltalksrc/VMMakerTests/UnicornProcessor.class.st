Class {
	#name : #UnicornProcessor,
	#superclass : #Object,
	#instVars : [
		'machineSimulator'
	],
	#category : #VMMakerTests
}

{ #category : #caching }
UnicornProcessor >> flushICacheFrom: anInteger to: anInteger2 [ 

	"Do nothing for now..."
]

{ #category : #registers }
UnicornProcessor >> fp [
	
	^ machineSimulator framePointerRegisterValue
]

{ #category : #accessing }
UnicornProcessor >> machineSimulator: aMachineSimulator [
	
	machineSimulator := aMachineSimulator
]

{ #category : #registers }
UnicornProcessor >> sp [
	
	^ machineSimulator stackPointerRegisterValue
]
