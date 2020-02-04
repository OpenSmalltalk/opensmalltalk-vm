Class {
	#name : #RelativeInstructionPrinter,
	#superclass : #InstructionPrinter,
	#instVars : [
		'printCode',
		'labels',
		'labelling'
	],
	#category : #VMMakerLoadingDependencies
}

{ #category : #'instruction decoding' }
RelativeInstructionPrinter >> jump: offset [
	"Print the Unconditional Jump bytecode."

	labelling
		ifTrue:
			[labels at: scanner pc + offset + 1 put: true.
			 self print: 'jumpBy: ', offset printString,
				' to: ', (scanner pc + offset - method initialPC) printString]
		ifFalse:
			[self print: 'jumpTo: ', (labels at: scanner pc + offset + 1)]
]

{ #category : #'instruction decoding' }
RelativeInstructionPrinter >> jump: offset if: condition [ 
	"Print the Conditional Jump bytecode."

	labelling
		ifTrue:
			[labels at: scanner pc + offset + 1 put: true.
			 self print: 
				(condition ifTrue: ['jumpTrueBy: '] ifFalse: ['jumpFalseBy: ']), offset printString,
				' to: ', (labelling
							ifTrue: [(scanner pc + offset - method initialPC) printString]
							ifFalse: [labels at: scanner pc + offset])]
		ifFalse:
			[self print: 
				(condition ifTrue: ['jumpTrueTo: '] ifFalse: ['jumpFalseTo: ']), (labels at: scanner pc + offset + 1)]
]

{ #category : #printing }
RelativeInstructionPrinter >> print: instruction [ 
	"Append to the receiver a description of the bytecode, instruction." 

	stream tab: self indent.
	labelling
		ifTrue: [stream print: oldPC - method initialPC; space]
		ifFalse: [stream tab].
	stream tab: (innerIndents at: oldPC).
	self printCode ifTrue:
		[stream nextPut: $<.
		 oldPC to: scanner pc - 1 do: 
			[:i | | code |
			code := (method at: i) radix: 16.
			stream
				nextPut: (code size < 2 ifTrue: [$0] ifFalse: [code at: 1]);
				nextPut: code last;
				space].
		 stream skip: -1; nextPut: $>; space].
	stream nextPutAll: instruction.
	stream cr.
	labelling ifFalse:
		[(labels at: scanner pc + 1) ~~ false ifTrue:
			[stream nextPutAll: (labels at: scanner pc + 1); nextPut: $:; cr]].
	oldPC := scanner pc
]

{ #category : #printing }
RelativeInstructionPrinter >> printCode [
	^printCode ~~ false
]

{ #category : #'initialize-release' }
RelativeInstructionPrinter >> printCode: aBoolean [
	printCode := aBoolean
]

{ #category : #printing }
RelativeInstructionPrinter >> printInstructionsOn: aStream [
	"Append to the stream, aStream, a description of each bytecode in the instruction stream."
	
	| label |
	labelling := true.
	labels := Array new: method size + 1 withAll: false.
	super printInstructionsOn: (String new: 1024) writeStream.
	label := 0.
	labels withIndexDo:
		[:bool :index|
		bool ifTrue: [labels at: index put: 'L', (label := label + 1) printString]].
	labelling := false.
	super printInstructionsOn: aStream
]

{ #category : #printing }
RelativeInstructionPrinter >> printInstructionsOn: aStream do: aBlock [
	"Append to the stream, aStream, a description of each bytecode in the instruction stream.
	  Evaluate aBlock with the receiver, the scanner and the stream after each instruction."
	
	| label |
	labelling := true.
	labels := Array new: method size withAll: false.
	super printInstructionsOn: (String new: 1024) writeStream do: [:ig :no :re|].
	label := 0.
	labels withIndexDo:
		[:bool :index|
		bool ifTrue: [labels at: index put: 'L', (label := label + 1) printString]].
	labelling := false.
	super printInstructionsOn: aStream do: aBlock
]
