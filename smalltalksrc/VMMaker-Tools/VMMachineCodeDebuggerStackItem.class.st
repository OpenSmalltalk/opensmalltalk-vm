Class {
	#name : #VMMachineCodeDebuggerStackItem,
	#superclass : #Object,
	#instVars : [
		'address',
		'machineSimulator'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #'instance creation' }
VMMachineCodeDebuggerStackItem class >> address: anInteger on: machineSimulator [ 
	
	^ self new
		address: anInteger;
		machineSimulator: machineSimulator;
		yourself
]

{ #category : #accessing }
VMMachineCodeDebuggerStackItem >> address [
	^ address
]

{ #category : #accessing }
VMMachineCodeDebuggerStackItem >> address: anInteger [ 
	address := anInteger
]

{ #category : #accessing }
VMMachineCodeDebuggerStackItem >> machineSimulator: anUnicornARMv8Simulator [ 
	machineSimulator := anUnicornARMv8Simulator
]

{ #category : #evaluating }
VMMachineCodeDebuggerStackItem >> specialRegister [

	machineSimulator sp = address ifTrue: [ ^ 'SP' ].
	machineSimulator fp = address ifTrue: [ ^ 'FP' ].
	^ ''
]

{ #category : #evaluating }
VMMachineCodeDebuggerStackItem >> value [ 

	^ machineSimulator wordAt: address
]
