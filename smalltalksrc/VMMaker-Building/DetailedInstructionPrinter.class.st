Class {
	#name : #DetailedInstructionPrinter,
	#superclass : #InstructionPrinter,
	#instVars : [
		'stackHeightComputer'
	],
	#category : #'VMMaker-Support'
}

{ #category : #'instance creation' }
DetailedInstructionPrinter class >> on: method [ 
	"Answer an instance of me on the argument, method."

	^self new method: method pc: method initialPC
]

{ #category : #'initialize-release' }
DetailedInstructionPrinter >> method: aMethod [
	super method: aMethod.
	stackHeightComputer := StackDepthFinder new method: aMethod pc: nil
]

{ #category : #'initialize-release' }
DetailedInstructionPrinter >> method: aMethod pc: pc [
	super method: aMethod.
	stackHeightComputer := StackDepthFinder new method: aMethod pc: pc
]

{ #category : #printing }
DetailedInstructionPrinter >> print: instruction [
	| current next |
	super print: instruction.
	current := stackHeightComputer stackp.
	stackHeightComputer interpretNextInstructionFor: stackHeightComputer.
	next := stackHeightComputer stackp.
	stream
		skip: -1;
		tab; tab; nextPut: $(;
		print: current.
	current ~= next ifTrue:
		[stream nextPut: $-; nextPut: $>; print: next].
	stream
		nextPut: $);
		cr;
		flush
]

{ #category : #accessing }
DetailedInstructionPrinter >> stackHeightComputer [
	"Answer the value of stackHeightComputer"

	^ stackHeightComputer
]

{ #category : #accessing }
DetailedInstructionPrinter >> stackHeightComputer: anObject [
	"Set the value of stackHeightComputer"

	stackHeightComputer := anObject
]
