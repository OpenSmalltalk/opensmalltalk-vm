"
SimulatorHarness provides machinery for executing code within a simulator that is initialized with an image but not up and running.
"
Class {
	#name : #SimulatorHarness,
	#superclass : #Object,
	#pools : [
		'VMObjectIndices'
	],
	#category : 'VMMaker-Support'
}

{ #category : #testing }
SimulatorHarness >> deny: aBooleanOrBlock [
	aBooleanOrBlock value ifTrue: [AssertionFailure signal: 'Assertion failed']
]

{ #category : #execution }
SimulatorHarness >> interpreter: sim object: receiver perform: selector withArguments: arguments [
	"Interpret an expression in oldHeap using oldInterpreter.
	 Answer the result."
	| fp savedpc savedsp savedStackPages result startByteCount |
	self assert: ({receiver. selector}, arguments allSatisfy:
					[:oop| oop isInteger and: [sim objectMemory addressCouldBeOop: oop]]).
	savedpc := sim localIP.
	savedsp := sim localSP.
	savedStackPages := Set with: sim stackPage.
	sim internalPush: receiver.
	arguments do: [:arg| sim internalPush: arg].
	sim
		argumentCount: arguments size;
		messageSelector: selector.
	fp := sim localFP.
	startByteCount := sim byteCount.
	"sim byteCount = 66849 ifTrue: [self halt]."
	sim normalSend.
	sim incrementByteCount. "otherwise, send is not counted"
	["sim printFrame: sim localFP WithSP: sim localSP"
	 "sim setBreakSelector: #elementsForwardIdentityTo:"
	 "sim byteCount = 66849 ifTrue: [self halt]."
	 "(sim byteCount > 7508930 and: [sim localFP = -16r27894]) ifTrue:
		[self halt]."
	 fp = sim localFP] whileFalse:
		[sim singleStep.
		 (savedStackPages includes: sim stackPage) ifFalse: "If the stack gets deep something has probably gone wrong..."
			[savedStackPages size > 20 ifTrue: [self halt].
			 savedStackPages add: sim stackPage]].
	result := sim internalPopStack.
	self assert: savedsp = sim localSP.
	self assert: sim localIP - 1 = savedpc.
	sim localIP: savedpc.
	^result
]

{ #category : #execution }
SimulatorHarness >> withExecutableInterpreter: sim do: aBlock [
	"With the oldInterpreter ready to execute code, evaluate aBlock,
	 then return the interpreter (and the heap) to the ``just snapshotted'' state."
	| savedpc savedfp initialContext finalContext |
	sim
		initStackPages;
		loadInitialContext;
		internalizeIPandSP.
	savedpc := sim localIP.
	savedfp := sim localFP.
	"sim printHeadFrame."
	aBlock cull: sim cull: self.
	"sim printHeadFrame."
	sim
		internalPush: sim localIP;
		externalizeIPandSP.
	"now undo the execution state"
	self assert: sim localFP = savedfp.
	initialContext := sim frameContext: savedfp.
	finalContext := sim voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
	self assert: initialContext = finalContext.
	self assert: sim localIP = savedpc.
	sim objectMemory
		storePointer: SuspendedContextIndex
		ofObject: sim activeProcess
		withValue: finalContext
]
