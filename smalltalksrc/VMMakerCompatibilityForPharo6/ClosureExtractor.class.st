"
A ClosureExtractor is a utility class that is used to extract all BlockClosures from a CompiledMethod. It inherits from InstructionClient and understands only one single message, namely that corresponding to the push closure bytecode instruction. Being sent this message, a ClosureExtractor will create a BlockClosure instance and evaluate the block it holds as an instance variable with that closure as parameter.
"
Class {
	#name : #ClosureExtractor,
	#superclass : #InstructionClient,
	#instVars : [
		'action',
		'scanner',
		'currentContext'
	],
	#category : #'VMMakerCompatibilityForPharo6-Kernel-Methods'
}

{ #category : #'instance creation' }
ClosureExtractor class >> withAction: aBlock andScanner: anInstructionStream [
	"The passed block must accept one value, which will be a BlockClosure."
	^ self new action: aBlock; scanner: anInstructionStream
]

{ #category : #accessing }
ClosureExtractor >> action [
	^ action
]

{ #category : #accessing }
ClosureExtractor >> action: aBlock [
	action := aBlock
]

{ #category : #'instruction decoding' }
ClosureExtractor >> blockReturnConstant: value [
	currentContext := currentContext sender
]

{ #category : #'instruction decoding' }
ClosureExtractor >> blockReturnTop [
	currentContext := currentContext sender
]

{ #category : #'instruction decoding' }
ClosureExtractor >> pushClosureCopyNumCopiedValues: numCopied numArgs: numArgs blockSize: blockSize [
	"Create a BlockClosure corresponding to the closure bytecode
	 and execute the action block with it. The created BlockClosure is only a pseudo value,
	 it is not populated with meaningful context and argument information."
	| block |
	block := BlockClosure
				outerContext: currentContext
				startpc: scanner pc
				numArgs: numArgs
				copiedValues: (Array new: numCopied)..
	currentContext := block asContextWithSender: currentContext.
	action value: block
]

{ #category : #'instruction decoding' }
ClosureExtractor >> pushFullClosure: aCompiledBlock numCopied: numCopied [
	"Create a BlockClosure corresponding to the closure bytecode
	 and execute the action block with it. The created BlockClosure is only a pseudo value,
	 it is not populated with meaningful context and argument information."
	| block |
	block := FullBlockClosure
				receiver: nil
				outerContext: currentContext
				method: aCompiledBlock
				copiedValues: (Array new: numCopied).
	currentContext := block asContextWithSender: currentContext.
	action value: block
]

{ #category : #accessing }
ClosureExtractor >> scanner [
	^ scanner
]

{ #category : #accessing }
ClosureExtractor >> scanner: anInstructionStream [
	scanner := anInstructionStream.
	currentContext := Context
							sender: nil
							receiver: nil
							method: scanner method
							arguments: (Array new: scanner method numArgs)
]
