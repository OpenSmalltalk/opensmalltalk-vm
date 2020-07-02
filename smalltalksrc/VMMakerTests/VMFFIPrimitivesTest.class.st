Class {
	#name : #VMFFIPrimitivesTest,
	#superclass : #VMAbstractPrimitiveTest,
	#category : #VMMakerTests
}

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> assertPopInEmptyStackFails [

	[ interpreter popSameThreadCalloutSuspendedProcess.
	self fail ]
		onErrorDo: [ :anError | 
			self
				assert: anError messageText
				equals: 'SameThreadCalloutSuspendedProcessStack is empty' ]
]

{ #category : #helpers }
VMFFIPrimitivesTest >> createExternalFunctionFor: aBlock withArgumentTypes: argumentTypes withReturnType: returnType [

	| functionAddress tfExternalFunction functionExternalAddress tfFunctionDefinition cif cifExternalAddress |

	functionAddress := interpreter libFFI registerFunction: aBlock.

	tfExternalFunction := self newObjectWithSlots: 2. 
	functionExternalAddress := self newExternalAddress: functionAddress. 
	tfFunctionDefinition := self newObjectWithSlots: 1.
	
	cif := interpreter libFFI newCif.
	cif argumentTypes: argumentTypes.
	cif returnType: returnType.
		
	cifExternalAddress := self newExternalAddress: (cif address). 

	memory storePointer: 0 ofObject: tfExternalFunction withValue: functionExternalAddress.
	memory storePointer: 1 ofObject: tfExternalFunction withValue: tfFunctionDefinition.
	memory storePointer: 0 ofObject: tfFunctionDefinition withValue: cifExternalAddress.	

	^ tfExternalFunction
]

{ #category : #helpers }
VMFFIPrimitivesTest >> createReturnFloatExternalFunctionFor: aBlock [

	^ self
		createExternalFunctionFor: aBlock
		withArgumentTypes: #()
		withReturnType: interpreter libFFI float
]

{ #category : #helpers }
VMFFIPrimitivesTest >> createReturnFloatExternalFunctionFor: aBlock withArgumentTypes: argumentTypes [

	^ self
		createExternalFunctionFor: aBlock
		withArgumentTypes: argumentTypes
		withReturnType: interpreter libFFI float
]

{ #category : #'tests - callbacks' }
VMFFIPrimitivesTest >> doCallout: tfExternalFunction with: parametersArray [
	
	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 
	
	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.

]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> doTestFuntionWithArgumentType: argumentType smalltalkValue: smalltalkValue expectedValue: expectedValue [

	| parametersArray tfExternalFunction savedValue |

	tfExternalFunction := self 
		createExternalFunctionFor:  [ :anArgument | savedValue := anArgument ] 
		withArgumentTypes: { argumentType } 
		withReturnType: interpreter libFFI void.
	
	parametersArray := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: parametersArray withValue: smalltalkValue.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self deny: interpreter failed.
	self assert: savedValue equals: expectedValue.
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> doTestFuntionWithArgumentType: argumentType smalltalkValue: smalltalkValue failsWith: expectedErrorCode [

	| parametersArray tfExternalFunction savedValue |

	tfExternalFunction := self 
		createExternalFunctionFor:  [ :anArgument | savedValue := anArgument ] 
		withArgumentTypes: { argumentType } 
		withReturnType: interpreter libFFI void.
	
	parametersArray := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: parametersArray withValue: smalltalkValue.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter failed.
	self assert: interpreter primFailCode equals: expectedErrorCode.
]

{ #category : #helpers }
VMFFIPrimitivesTest >> interpreterClass [
	
	^ VMTestMockInterpreter
]

{ #category : #helpers }
VMFFIPrimitivesTest >> newExternalAddress: anInteger [

	| anExternalAddress |
	anExternalAddress := self
		newObjectWithSlots: (memory numSlotsForBytes: self wordSize)
		format: (memory byteFormatForNumBytes: self wordSize)
		classIndex: memory classExternalAddressIndex.
		
	memory storePointer: 0 ofObject: anExternalAddress withValue: anInteger.
	^ anExternalAddress
]

{ #category : #helpers }
VMFFIPrimitivesTest >> readyProcesses [
	
	| collection |
	collection := OrderedCollection new.
	interpreter processesInProcessListDo: [ :e | collection add: e ].
	^ collection
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithDoubleArgumentIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI double
		smalltalkValue: (memory floatObjectOf: 17.0)
		expectedValue: 17.0
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithFloatArgumentIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI float
		smalltalkValue: (memory floatObjectOf: 17.0)
		expectedValue: 17.0
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithPointerArgumentIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI pointer
		smalltalkValue: (self newExternalAddress: 17)
		expectedValue: 17
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT16ArgumentWithNegativeValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint16
		smalltalkValue: (memory integerObjectOf: -42)
		expectedValue: -42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT16ArgumentWithPositiveValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint16
		smalltalkValue: (memory integerObjectOf: 42)
		expectedValue: 42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT32ArgumentWithNegativeValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint32
		smalltalkValue: (memory integerObjectOf: -42)
		expectedValue: -42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT32ArgumentWithPositiveValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint32
		smalltalkValue: (memory integerObjectOf: 42)
		expectedValue: 42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT64ArgumentWithNegativeValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint64
		smalltalkValue: (memory integerObjectOf: -42)
		expectedValue: -42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT64ArgumentWithPositiveValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint64
		smalltalkValue: (memory integerObjectOf: 42)
		expectedValue: 42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT8ArgumentWithNegativeValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint8
		smalltalkValue: (memory integerObjectOf: -42)
		expectedValue: -42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithSINT8ArgumentWithPositiveValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI sint8
		smalltalkValue: (memory integerObjectOf: 42)
		expectedValue: 42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithUINT32ArgumentWithNegatieValueFails [

	self
		doTestFuntionWithArgumentType: interpreter libFFI uint32
		smalltalkValue: (memory integerObjectOf: -42)
		failsWith: PrimErrBadArgument
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithUINT32ArgumentWithPositiveValueIsMarshalledCorrectly [

	self
		doTestFuntionWithArgumentType: interpreter libFFI uint32
		smalltalkValue: (memory integerObjectOf: 42)
		expectedValue: 42
]

{ #category : #'tests - parameters marshalling' }
VMFFIPrimitivesTest >> testCalloutWithoutArgumentsMarshallsCorrectly [

	| parametersArray tfExternalFunction functionCalled |

	functionCalled := false.
	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ functionCalled := true. 7.0 ].
	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: functionCalled.
]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPopSameThreadCalloutSuspendedProcessInEmptyStackRaisesError [

 	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	
	
	self assertPopInEmptyStackFails
]

{ #category : #'tests - callbacks' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCallbackInCalloutSuspendsActiveProcess [

	| parametersArray tfExternalFunction oldActiveProcess callbackContext |

	callbackContext	:= VMCallbackContext new.

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 
		interpreter ptEnterInterpreterFromCallback: callbackContext ].
	
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter interpreteBlock: [ | oldActiveProcessContext |
		"The test will enter the callout primitive, call this callback, assert and then finish.
		We do not return from the callback in this test"
		
		"Assert that at callback time:
		 - the process doing the callout is suspended (has a valid instruction pointer)
		 - not stored in the ready list
		 - not stored as active process"
		oldActiveProcessContext := memory fetchPointer: SuspendedContextIndex ofObject: oldActiveProcess.
		self assert: (interpreter isLiveContext: oldActiveProcessContext).
		self deny: (self readyProcesses includes: oldActiveProcess).
		^ self deny: interpreter activeProcess equals: oldActiveProcess ].
	
	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
]

{ #category : #'tests - callbacks' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCallbackReturnKeepsAllOtherProcessesInReady [

	| parametersArray tfExternalFunction callbackContext processBefore |

	callbackContext	:= VMCallbackContext new.
	callbackContext trampoline: ExitInterpreter new.

	processBefore := self readyProcesses.

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 
		[interpreter ptEnterInterpreterFromCallback: callbackContext] on: ExitInterpreter do: [ 3.14 ] ].
	
	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter interpreteBlock: [ interpreter ptExitInterpreterToCallback: callbackContext ].
	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assertCollection: self readyProcesses hasSameElements: processBefore
]

{ #category : #'tests - callbacks' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCallbackReturnResumesCalloutProcess [

	| parametersArray tfExternalFunction oldActiveProcess callbackContext |

	callbackContext	:= VMCallbackContext new.
	callbackContext trampoline: ExitInterpreter new.

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 
		[interpreter ptEnterInterpreterFromCallback: callbackContext] 
			on: ExitInterpreter do: [ 3.14 ] ].
	
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter interpreteBlock: [ interpreter ptExitInterpreterToCallback: callbackContext ].
	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter activeProcess equals: oldActiveProcess.
]

{ #category : #'tests - callouts' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutMaintainsActiveProcess [

	| parametersArray tfExternalFunction oldActiveProcess |

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 7.0 ].
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter activeProcess equals: oldActiveProcess
]

{ #category : #'tests - callouts' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutReturningDoublePushSmallFloatInStack [
	| parametersArray tfExternalFunction |

	tfExternalFunction := self
		createExternalFunctionFor: [ 7.0 ]
		withArgumentTypes: #()
		withReturnType: interpreter libFFI double.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray.

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.

	self assert: interpreter stackTop equals: (memory floatObjectOf: 7.0)
]

{ #category : #'tests - callouts' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutReturningFloatPushSmallFloatInStack [

	| parametersArray tfExternalFunction |

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 7.0 ].
	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter stackTop equals: (memory floatObjectOf: 7.0)
]

{ #category : #'tests - callouts' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutReturningVoidPushesTheReceiver [

	| parametersArray tfExternalFunction |

	tfExternalFunction := self createExternalFunctionFor: [ ] withArgumentTypes: #() withReturnType: interpreter libFFI void.
	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory trueObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter stackTop equals: memory trueObject
]

{ #category : #'tests - callouts' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutShouldKeepTheNewMethodVariable [

	| parametersArray tfExternalFunction oldActiveProcess callbackContext |

	callbackContext	:= VMCallbackContext new.
	callbackContext trampoline: ExitInterpreter new.

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 
		[interpreter ptEnterInterpreterFromCallback: callbackContext] 
			on: ExitInterpreter do: [ 3.14 ] ].
	
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter interpreteBlock: [ interpreter ptExitInterpreterToCallback: callbackContext ].
	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter activeProcess equals: oldActiveProcess.
]

{ #category : #'tests - callbacks' }
VMFFIPrimitivesTest >> testPrimitiveSameThreadReentrantCallbackRestoresCalloutProcess [

	| parametersArray tfExternalFunction oldActiveProcess callbackContext numberOfCallbacks innerCallbackContext tfExternalFunction2 |

	callbackContext	:= VMCallbackContext new.
	callbackContext trampoline: ExitInterpreter new.

	numberOfCallbacks := 0.

	innerCallbackContext	:= VMCallbackContext new.
	innerCallbackContext trampoline: ExitInterpreter new.

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 
		[interpreter ptEnterInterpreterFromCallback: callbackContext] 
			on: ExitInterpreter do: [ 3.14 ] ].

	tfExternalFunction2 := self createReturnFloatExternalFunctionFor: [ 
		[interpreter ptEnterInterpreterFromCallback: innerCallbackContext] 
			on: ExitInterpreter do: [ 3.14 ] ].
	
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter interpreteBlock: [ 
		numberOfCallbacks := numberOfCallbacks + 1.
		numberOfCallbacks = 1 ifTrue: [  
				self doCallout: tfExternalFunction2 with: parametersArray ].
			
		interpreter ptExitInterpreterToCallback: callbackContext ].

	self doCallout: tfExternalFunction with: parametersArray.
	
	self assert: interpreter activeProcess equals: oldActiveProcess.
]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushPushThenPopPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsFirstPushedProcess [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	interpreter popSameThreadCalloutSuspendedProcess.
	
	self assert: interpreter popSameThreadCalloutSuspendedProcess equals: aProcess.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushPushThenPopPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsFirstPushedProcessWithNilNextLink [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	interpreter popSameThreadCalloutSuspendedProcess.
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: interpreter popSameThreadCalloutSuspendedProcess) equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsLastPushedProcess [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	self assert: interpreter popSameThreadCalloutSuspendedProcess equals: anotherProcess.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsLastPushedProcessWithNilNextLink [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: interpreter popSameThreadCalloutSuspendedProcess) equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushSameThreadCalloutSuspendedProcessInEmptyStackStoresThePassedProcess [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createProcessFor: memory nilObject priority: 2.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: (memory splObj: SuspendedProcessInCallout) equals: aProcess.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushSameThreadCalloutSuspendedProcessInEmptyStackUpdatesNextLinkWithNil [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: aProcess) equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushThenPopPopSameThreadCalloutSuspendedProcessInEmptyStackFails [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 

	interpreter popSameThreadCalloutSuspendedProcess.
	
	self assertPopInEmptyStackFails	

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsProcessWithNilInNextLink [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: aProcess)  equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsPushedProcess [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: interpreter popSameThreadCalloutSuspendedProcess equals: aProcess.

]

{ #category : #'tests - helpers' }
VMFFIPrimitivesTest >> testReadAddressReadsTheValidAddressValue [

	| anExternalAddress |
	anExternalAddress := self newExternalAddress: 4.
	self assert: (interpreter readAddress: anExternalAddress) equals: 4
]
