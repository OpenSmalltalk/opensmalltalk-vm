Class {
	#name : #VMMachineCodeMethod,
	#superclass : #Object,
	#instVars : [
		'virtualMachine',
		'cogMethodSurrogate'
	],
	#pools : [
		'VMStackFrameOffsets'
	],
	#category : #'VMMakerTests-Visualisation'
}

{ #category : #'instance creation' }
VMMachineCodeMethod class >> newOnInterpreter: aVirtualMachine cogMethodSurrogate: aCogMethodSurrogate [
	
	^ self new
		virtualMachine: aVirtualMachine;
		cogMethodSurrogate: aCogMethodSurrogate;
		yourself
]

{ #category : #accessing }
VMMachineCodeMethod >> cogMethodSurrogate [
	^ cogMethodSurrogate
]

{ #category : #accessing }
VMMachineCodeMethod >> cogMethodSurrogate: anObject [
	cogMethodSurrogate := anObject
]

{ #category : #accessing }
VMMachineCodeMethod >> disassemble [
	| methodEntry instructions |
	methodEntry := cogMethodSurrogate asInteger + virtualMachine cogit entryOffset.
	instructions := virtualMachine cogit processor machineSimulator
		disassembleFrom: methodEntry
		to: cogMethodSurrogate asInteger + cogMethodSurrogate asInteger.
		
	^ '
' join: (instructions collect: [:i | i assemblyCodeString])
]

{ #category : #accessing }
VMMachineCodeMethod >> virtualMachine [
	^ virtualMachine
]

{ #category : #accessing }
VMMachineCodeMethod >> virtualMachine: anObject [
	virtualMachine := anObject
]
