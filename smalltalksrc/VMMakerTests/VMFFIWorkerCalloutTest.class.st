Class {
	#name : #VMFFIWorkerCalloutTest,
	#superclass : #VMAbstractFFITest,
	#instVars : [
		'aFunctionBlock',
		'tfExternalFunction',
		'parametersArray',
		'worker',
		'workerOop',
		'semaphoreIndex'
	],
	#category : #VMMakerTests
}

{ #category : #tests }
VMFFIWorkerCalloutTest >> doWorkerCallWithArguments: smalltalkValues ofTypes: argumentTypes [

	^ self doWorkerCallWithArguments: smalltalkValues ofTypes: argumentTypes returnType: interpreter libFFI void
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> doWorkerCallWithArguments: smalltalkValues ofTypes: argumentTypes returnType: returnType [

	aFunctionBlock := [ self fail: 'It should enqueue it, not execute it' ].

	tfExternalFunction := self
		                      createExternalFunctionFor: aFunctionBlock
		                      withArgumentTypes: argumentTypes
		                      withReturnType: returnType.

	parametersArray := self newArrayWith: smalltalkValues.

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

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutEnqueuesOnlyOneTask [

	self doWorkerCallWithArguments: {} ofTypes: {}.
	self assert: interpreter libFFI testWorker tasks size equals: 1
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutReleasesAllAllocatedMemoryIfPrimitiveFails [

	| previous |
	previous := interpreter allocatedElements size.
	
	self doWorkerCallWithArguments: {
		memory floatObjectOf: 1.0.
		memory floatObjectOf: 2.0.
		memory integerObjectOf: 3.
		memory integerObjectOf: 4.
		memory floatObjectOf: 5.0 } ofTypes: { 
		interpreter libFFI float.
		interpreter libFFI double.
		interpreter libFFI uint32.
		interpreter libFFI sint8.
		interpreter libFFI sint8 }
	returnType: interpreter libFFI sint32.

	self assert: interpreter failed.
	self assert: interpreter allocatedElements size equals: previous.
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutReturningVoidDoesNotAllocateReturnHolder [

	self doWorkerCallWithArguments: {} ofTypes: {}.

	self assert: interpreter libFFI testWorker tasks first returnHolderAddress isNil
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutWithParametersAllocatesArgumentHoldersAndReturnHolderInCHeap [

	| previous |
	previous := interpreter allocatedElements size.
	
	self doWorkerCallWithArguments: {
		memory floatObjectOf: 1.0.
		memory floatObjectOf: 2.0.
		memory integerObjectOf: 3.
		memory integerObjectOf: 4.
		self newExternalAddress: 5 } ofTypes: { 
		interpreter libFFI float.
		interpreter libFFI double.
		interpreter libFFI uint32.
		interpreter libFFI sint8.
		interpreter libFFI pointer }
	returnType: interpreter libFFI sint32.

	self assert: interpreter allocatedElements size equals: previous + 7.
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutWithoutParametersAndWithReturnAllocateJustOne [

	| previous |
	previous := interpreter allocatedElements size.
	
	self doWorkerCallWithArguments: {} ofTypes: {} returnType: interpreter libFFI sint32.

	self assert: interpreter allocatedElements size equals: previous + 1.
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutWithoutParametersAndWithoutReturnDoesNotAllocate [

	| previous |
	previous := interpreter allocatedElements size.
	
	self doWorkerCallWithArguments: {} ofTypes: {}.

	self assert: interpreter allocatedElements size equals: previous.
]

{ #category : #tests }
VMFFIWorkerCalloutTest >> testPrimitiveWorkerCalloutWithoutParametersHasNilAsParametersPointer [

	self doWorkerCallWithArguments: {} ofTypes: {}.

	self assert: interpreter libFFI testWorker tasks first parametersAddress isNil
]
