Class {
	#name : #StackMTInterpreterSimulatorForTest,
	#superclass : #StackMTInterpreterSimulator,
	#category : #'VMMaker-MT-Tests'
}

{ #category : #'instance creation' }
StackMTInterpreterSimulatorForTest class >> onObjectMemory: anObjectMemory options: optionsDictionaryOrArray [

	| interpreter |
	self
		initializeWithOptions: optionsDictionaryOrArray
		objectMemoryClass: (anObjectMemory ifNotNil: [anObjectMemory class]).
	^ (interpreter := self basicNew)
		threadManager: (VMMockCogThreadManager new
			setInterpreter: interpreter
			cogit: nil);
		objectMemory: anObjectMemory;
		initialize
]

{ #category : #simulation }
StackMTInterpreterSimulatorForTest >> enterSmalltalkExecutiveImplementation [

	"Do not return to interpreter"
	^ 0
]

{ #category : #simulation }
StackMTInterpreterSimulatorForTest >> ioNewOS: function Thread: vmThread [
	"Do it synchronously"
	self perform: function with: vmThread.
	^0
]

{ #category : #'as yet unclassified' }
StackMTInterpreterSimulatorForTest >> methodCallingPush [
	<api>
	self pushLiteralVariable: 1.
]
