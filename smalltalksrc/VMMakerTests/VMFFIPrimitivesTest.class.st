Class {
	#name : #VMFFIPrimitivesTest,
	#superclass : #VMAbstractPrimitiveTest,
	#category : #VMMakerTests
}

{ #category : #helpers }
VMFFIPrimitivesTest >> createReturnFloatExternalFunctionFor: aBlock [ 

	| functionAddress tfExternalFunction functionExternalAddress tfFunctionDefinition cif cifExternalAddress |

	functionAddress := interpreter libFFI registerFunction: aBlock.

	tfExternalFunction := self newObjectWithSlots: 2. 
	functionExternalAddress := self newExternalAddress: functionAddress. 
	tfFunctionDefinition := self newObjectWithSlots: 1.
	
	cif := interpreter libFFI newCif.
	cif argumentTypes: #().
	cif returnType: interpreter libFFI float.
		
	cifExternalAddress := self newExternalAddress: (cif address). 

	memory storePointer: 0 ofObject: tfExternalFunction withValue: functionExternalAddress.
	memory storePointer: 1 ofObject: tfExternalFunction withValue: tfFunctionDefinition.
	memory storePointer: 0 ofObject: tfFunctionDefinition withValue: cifExternalAddress.	

	^ tfExternalFunction
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

{ #category : #tests }
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
	interpreter primitiveSameThreadCallout.
]

{ #category : #tests }
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
	interpreter primitiveSameThreadCallout.
	
	self assertCollection: self readyProcesses hasSameElements: processBefore
]

{ #category : #tests }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCallbackReturnResumesCalloutProcess [

	| parametersArray tfExternalFunction oldActiveProcess callbackContext |

	callbackContext	:= VMCallbackContext new.
	callbackContext trampoline: ExitInterpreter new.

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 
		[interpreter ptEnterInterpreterFromCallback: callbackContext] on: ExitInterpreter do: [ 3.14 ] ].
	
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter interpreteBlock: [ interpreter ptExitInterpreterToCallback: callbackContext ].
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter activeProcess equals: oldActiveProcess.
]

{ #category : #tests }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutMaintainsActiveProcess [

	| parametersArray tfExternalFunction oldActiveProcess |

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 7.0 ].
	oldActiveProcess := interpreter activeProcess.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter activeProcess equals: oldActiveProcess
]

{ #category : #tests }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutReturningFloatPushSmallFloatInStack [

	| parametersArray tfExternalFunction |

	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ 7.0 ].
	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter stackTop equals: (memory floatObjectOf: 7.0)
]

{ #category : #tests }
VMFFIPrimitivesTest >> testPrimitiveSameThreadCalloutWithoutArgumentsCallsCorrectFunction [

	| parametersArray tfExternalFunction functionCalled |

	functionCalled := false.
	tfExternalFunction := self createReturnFloatExternalFunctionFor: [ functionCalled := true. 7.0 ].
	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 

	interpreter primitiveSameThreadCallout.
	
	self assert: functionCalled.
]

{ #category : #tests }
VMFFIPrimitivesTest >> testReadAddressReadsTheValidAddressValue [

	| anExternalAddress |
	anExternalAddress := self newExternalAddress: 4.
	self assert: (interpreter readAddress: anExternalAddress) equals: 4
]
