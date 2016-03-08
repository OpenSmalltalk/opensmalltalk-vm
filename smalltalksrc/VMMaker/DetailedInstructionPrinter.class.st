Class {
	#name : #DetailedInstructionPrinter,
	#superclass : #InstructionPrinter,
	#instVars : [
		'stackHeightComputer',
		'encoderClass'
	],
	#category : 'VMMaker-Support'
}

{ #category : #'instance creation' }
DetailedInstructionPrinter class >> on: method [ 
	"Answer an instance of me on the argument, method."

	^self new method: method pc: method initialPC
]

{ #category : #accessing }
DetailedInstructionPrinter >> encoderClass [

	^encoderClass
]

{ #category : #accessing }
DetailedInstructionPrinter >> encoderClass: anObject [

	encoderClass := anObject
]

{ #category : #decoding }
DetailedInstructionPrinter >> interpretNextInstructionFor: client [
	^encoderClass
		ifNil: [super interpretNextInstructionFor: client]
		ifNotNil: [encoderClass interpretNextInstructionFor: client in: self]
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

{ #category : #printing }
DetailedInstructionPrinter >> printInstructionsOn: aStream [
	"Append to the stream, aStream, a description of each bytecode in the
	 instruction stream."
	
	| end |
	encoderClass ifNil:
		[^super printInstructionsOn: aStream].
	stackHeightComputer encoderClass: encoderClass.
	stream := aStream.
	scanner := InstructionStream on: method.
	end := method endPC.
	oldPC := scanner pc.
	innerIndents := Array new: end withAll: 0.
	[scanner pc <= end] whileTrue:
		[encoderClass interpretNextInstructionFor: self in: scanner]
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
