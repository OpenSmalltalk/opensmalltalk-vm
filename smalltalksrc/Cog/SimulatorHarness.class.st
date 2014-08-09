Class {
	#name : #SimulatorHarness,
	#superclass : #Object,
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'bootstrap methods' }
SimulatorHarness >> interpreter: sim object: receiver perform: selector withArguments: arguments [
	"Interpret an expression in oldHeap using oldInterpreter.
	 Answer the result."
	| fp savedpc savedsp result startByteCount |
	self assert: ({receiver. selector}, arguments allSatisfy:
					[:oop| oop isInteger and: [sim objectMemory addressCouldBeOop: oop]]).
	savedpc := sim localIP.
	savedsp := sim localSP.
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
		[sim singleStep].
	result := sim internalPopStack.
	self assert: savedsp = sim localSP.
	self assert: sim localIP - 1 = savedpc.
	sim localIP: savedpc.
	^result
]

{ #category : #'bootstrap methods' }
SimulatorHarness >> withExecutableInterpreter: sim do: aBlock [
	"With the oldInterpreter ready to execute code, evaluate aBlock,
	 then return the interpreter (and the heap) to the ``just snapshotted'' state."
	| savedpc initialContext finalContext |
	sim
		initStackPages;
		loadInitialContext;
		internalizeIPandSP.
	initialContext := sim frameContext: sim localFP.
	savedpc := sim localIP.
	"sim printHeadFrame."
	aBlock value.
	"sim printHeadFrame."
	sim
		internalPush: sim localIP;
		externalizeIPandSP.
	"now undo the execution state"
	finalContext := sim voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
	self assert: initialContext = finalContext.
	self assert: sim localIP = savedpc.
	sim objectMemory
		storePointer: SuspendedContextIndex
		ofObject: sim activeProcess
		withValue: finalContext
]
