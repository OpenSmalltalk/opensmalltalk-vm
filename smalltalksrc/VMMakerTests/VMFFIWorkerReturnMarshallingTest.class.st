Class {
	#name : #VMFFIWorkerReturnMarshallingTest,
	#superclass : #VMFFIReturnMarshallingTest,
	#instVars : [
		'tfExternalFunction',
		'returnHolder',
		'cif',
		'parameters',
		'semaphoreIndex',
		'task',
		'taskAddressOop',
		'worker',
		'workerOop'
	],
	#category : #VMMakerTests
}

{ #category : #'tests - marshalling return' }
VMFFIWorkerReturnMarshallingTest >> doTestCalloutWithReturnType: aLibFFIType returnValue: valueToReturn asserting: aBlock [

	tfExternalFunction := self
		createExternalFunctionFor: [ valueToReturn ]
		withArgumentTypes: #()
		withReturnType: aLibFFIType.

	returnHolder := interpreter malloc: aLibFFIType size.
	aLibFFIType fromSmalltalk: valueToReturn putInto: returnHolder.
	
	cif := interpreter getHandlerAsCif: (memory fetchPointer: 1 ofObject: tfExternalFunction).

	parameters := interpreter 
		allocateParameters: 2 
		using: [ :aNumber | interpreter calloc: (interpreter sizeof: #'void *') _: aNumber ].
	
	task := interpreter worker_task_new: tfExternalFunction _: cif _: parameters _: returnHolder _: semaphoreIndex.

	taskAddressOop := self newExternalAddress: task asInteger.

	worker := interpreter libFFI testWorker.	
	workerOop := self newObjectWithSlots: 1.

	memory
		storePointer: 0
		ofObject: workerOop
		withValue: (self newExternalAddress: worker asInteger).

	worker tasks add: task.
	
	interpreter push: workerOop.
	interpreter push: taskAddressOop.
	
	interpreter primitiveWorkerExtractReturnValue.
	
	aBlock value.
]

{ #category : #'tests - marshalling return' }
VMFFIWorkerReturnMarshallingTest >> testPrimitiveCalloutReturningVoidPushesTheReceiver [

	self 
		doTestCalloutWithReturnType: interpreter libFFI void
		returnValue: nil 
		asserting: [ self assert: interpreter stackTop equals: workerOop].
]
