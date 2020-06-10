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
UnicornProcessor >> pc: anInteger [ 
	
	^ machineSimulator instructionPointerValue: anInteger
]

{ #category : #registers }
UnicornProcessor >> rbp: anInteger [ 
	
	machineSimulator rbp: anInteger
]

{ #category : #registers }
UnicornProcessor >> rcx: anInteger [ 
	
	machineSimulator rcx: anInteger
]

{ #category : #registers }
UnicornProcessor >> rdx: anInteger [ 
	
	machineSimulator rdx: anInteger
]

{ #category : #registers }
UnicornProcessor >> rsp: anInteger [ 
	
	machineSimulator rsp: anInteger
]

{ #category : #initialization }
UnicornProcessor >> setFramePointer: framePointer stackPointer: stackPointer [
	
	machineSimulator framePointerRegisterValue: framePointer.
	machineSimulator stackPointerRegisterValue: stackPointer
]

{ #category : #registers }
UnicornProcessor >> sp [
	
	^ machineSimulator stackPointerRegisterValue
]
