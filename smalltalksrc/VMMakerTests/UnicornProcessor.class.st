Class {
	#name : #UnicornProcessor,
	#superclass : #Object,
	#instVars : [
		'machineSimulator'
	],
	#category : #'VMMakerTests-Unicorn'
}

{ #category : #'as yet unclassified' }
UnicornProcessor >> cResultRegister: anInteger [ 
	
	machineSimulator returnRegisterValue: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> ebp: anInteger [ 
	
	machineSimulator ebp: anInteger
]

{ #category : #registers }
UnicornProcessor >> edx: anInteger [ 
	
	^ machineSimulator edx: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> esp: anInteger [ 
	
	machineSimulator esp: anInteger
]

{ #category : #caching }
UnicornProcessor >> flushICacheFrom: anInteger to: anInteger2 [ 

	"Do nothing for now..."
]

{ #category : #registers }
UnicornProcessor >> fp [
	
	^ machineSimulator framePointerRegisterValue
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> initializeStackFor: aCompiler [
	
	"Initialize the machine code simulator"
	machineSimulator := UnicornSimulator perform: aCompiler backend class ISA asSymbol.
	machineSimulator memory: aCompiler objectMemory.
	aCompiler objectMemory memory memoryObject pinInMemory.
	machineSimulator mapMemory: aCompiler objectMemory memory memoryObject at: aCompiler objectMemory memory initialAddress "just some address not 0".
	
	"As for the ARMv8 Arm® Architecture Reference Manual
	
	D1.8.2 SP alignment checking
	A misaligned stack pointer is where bits[3:0] of the stack pointer are not 0b0000, when the stack pointer is used as the base address of the calculation, regardless of any offset applied by the instruction.
	
	Meaning that the stack should be aligned to 16 bytes"
	aCompiler setStackAlignment: 16 expectedSPOffset: 0 expectedFPOffset: 0.
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> machineSimulator [
	^ machineSimulator
]

{ #category : #accessing }
UnicornProcessor >> machineSimulator: aMachineSimulator [
	
	machineSimulator := aMachineSimulator
]

{ #category : #registers }
UnicornProcessor >> pc: anInteger [ 
	
	^ machineSimulator instructionPointerValue: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> postCallArgumentsNumArgs: anInteger in: aSpurSimulatedMemory [ 
	
	^ machineSimulator postCallArgumentsNumArgs: anInteger in: aSpurSimulatedMemory
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> r10: anInteger [ 
	
	machineSimulator r10: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> r11: anInteger [ 
	
	machineSimulator r11: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> r5: anInteger [ 

	machineSimulator r5: anInteger 
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

{ #category : #'as yet unclassified' }
UnicornProcessor >> runInMemory: aMemory minimumAddress: minimumAddress readOnlyBelow: minimumWritableAddress [


	^ machineSimulator startAt: machineSimulator instructionPointerValue
		until: 0
		timeout: 0
		count: 0
]

{ #category : #initialization }
UnicornProcessor >> setFramePointer: framePointer stackPointer: stackPointer [
	
	machineSimulator framePointerRegisterValue: framePointer.
	machineSimulator stackPointerRegisterValue: stackPointer
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> simulateJumpCallOf: anInteger memory: aSpurSimulatedMemory [

	machineSimulator simulateJumpCallOf: anInteger memory: aSpurSimulatedMemory
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [

	machineSimulator simulateLeafCallOf: address nextpc: nextpc memory: aMemory
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> smashRegistersWithValuesFrom: base by: step [
	
	machineSimulator smashRegistersWithValuesFrom: base by: step
]

{ #category : #registers }
UnicornProcessor >> sp [
	
	^ machineSimulator stackPointerRegisterValue
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> sp: anInteger [ 
	
	machineSimulator stackPointerRegisterValue: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> x12: anInteger [ 
	
	machineSimulator x12: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> x1: anInteger [ 

	machineSimulator x1: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> x28: anInteger [ 
	
	machineSimulator x28: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> x29: anInteger [ 
	
	machineSimulator x29: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> x5: anInteger [ 
	
	machineSimulator x5: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> x7: anInteger [ 
	
	machineSimulator x7: anInteger
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> xzr [
	
	^ machineSimulator xzr
]

{ #category : #'as yet unclassified' }
UnicornProcessor >> xzr: anInteger [ 
	
	machineSimulator xzr: anInteger
]
