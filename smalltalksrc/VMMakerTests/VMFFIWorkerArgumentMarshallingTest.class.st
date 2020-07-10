Class {
	#name : #VMFFIWorkerArgumentMarshallingTest,
	#superclass : #VMFFIArgumentMarshallingTest,
	#instVars : [
		'aFunctionBlock',
		'tfExternalFunction',
		'parametersArray',
		'worker',
		'workerOop',
		'semaphoreIndex',
		'task',
		'savedValue'
	],
	#category : #VMMakerTests
}

{ #category : #implementation }
VMFFIWorkerArgumentMarshallingTest >> doTestFuntionWithArgumentType: argumentType smalltalkValue: smalltalkValue expectedValue: expectedValue [

	self doWorkerCallWithValue: smalltalkValue ofType: argumentType.

	self deny: interpreter failed description: 'The primitive call should not fail'.

	"It should be only one task in the worker"	
	self assert: worker tasks size equals: 1.

	"Extracting the value stored in the task"
	task := worker tasks at: 1.
	savedValue := argumentType marshallToSmalltalk: (task parametersAddress at: 0).

	"The stored value in the worker task should be the expected"
	self assert: savedValue equals: expectedValue
]

{ #category : #implementation }
VMFFIWorkerArgumentMarshallingTest >> doTestFuntionWithArgumentType: argumentType smalltalkValue: smalltalkValue failsWith: expectedErrorCode [

	self doWorkerCallWithValue: smalltalkValue ofType: argumentType.
	
	self assert: interpreter failed.
	self assert: interpreter primFailCode equals: expectedErrorCode.
]

{ #category : #implementation }
VMFFIWorkerArgumentMarshallingTest >> doWorkerCallWithValue: smalltalkValue ofType: argumentType [

	aFunctionBlock := [ :anArgument | self fail: 'It should enqueue it, not execute it' ].

	tfExternalFunction := self
		                      createExternalFunctionFor: aFunctionBlock
		                      withArgumentTypes: { argumentType }
		                      withReturnType: interpreter libFFI void.

	parametersArray := self newObjectWithSlots: 1.

	memory
		storePointer: 0
		ofObject: parametersArray
		withValue: smalltalkValue.

	worker := interpreter libFFI testWorker.

	workerOop := self newObjectWithSlots: 1.

	memory
		storePointer: 0
		ofObject: workerOop
		withValue: (self newExternalAddress: worker asInteger).

	semaphoreIndex := 99.

	interpreter push: workerOop.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray.
	interpreter push: semaphoreIndex.
	interpreter argumentCount: 4.
	interpreter primitiveWorkerCallout
]

{ #category : #running }
VMFFIWorkerArgumentMarshallingTest >> setUp [ 

	super setUp.
	interpreter libFFI testWorker clear
]

{ #category : #tests }
VMFFIWorkerArgumentMarshallingTest >> testCalloutWithoutArgumentsMarshallsCorrectly [

	aFunctionBlock := [ :anArgument | self fail: 'It should enqueue it, not execute it' ].

	tfExternalFunction := self
		                      createExternalFunctionFor: aFunctionBlock
		                      withArgumentTypes: {}
		                      withReturnType: interpreter libFFI void.

	parametersArray := self newObjectWithSlots: 0.

	worker := interpreter libFFI testWorker.

	workerOop := self newObjectWithSlots: 1.

	memory
		storePointer: 0
		ofObject: workerOop
		withValue: (self newExternalAddress: worker asInteger).

	semaphoreIndex := 99.

	interpreter push: workerOop.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray.
	interpreter push: semaphoreIndex.
	interpreter argumentCount: 4.
	interpreter primitiveWorkerCallout.
	
	self deny: interpreter failed.
	
	"Extracting the value stored in the task"
	task := worker tasks at: 1.

	self assert: task returnHolderAddress equals: nil.
	self assert: task parametersAddress equals: nil.	
]
