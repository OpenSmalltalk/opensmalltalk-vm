Class {
	#name : #RelativeDetailedInstructionPrinter,
	#superclass : #RelativeInstructionPrinter,
	#instVars : [
		'stackHeightComputer',
		'saveLabel'
	],
	#category : #'VMMaker-Support'
}

{ #category : #'instance creation' }
RelativeDetailedInstructionPrinter class >> on: method [ 
	"Answer an instance of me on the argument, method."

	^self new method: method pc: method initialPC
]

{ #category : #printing }
RelativeDetailedInstructionPrinter >> emitLabelIfAnyFor: pc on: aStream [
	saveLabel := String streamContents: [:s| super emitLabelIfAnyFor: pc on: s]
]

{ #category : #'initialize-release' }
RelativeDetailedInstructionPrinter >> method: aMethod [
	super method: aMethod.
	stackHeightComputer := StackDepthFinder new method: aMethod pc: nil
]

{ #category : #'initialize-release' }
RelativeDetailedInstructionPrinter >> method: aMethod pc: pc [
	super method: aMethod.
	stackHeightComputer := StackDepthFinder new method: aMethod pc: pc
]

{ #category : #printing }
RelativeDetailedInstructionPrinter >> print: instruction [
	| current next |
	super print: instruction.
	labelling ifFalse:
		[current := stackHeightComputer stackp.
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
			flush.
		 saveLabel isEmpty ifFalse:
			[stream nextPutAll: saveLabel; flush]]
]
