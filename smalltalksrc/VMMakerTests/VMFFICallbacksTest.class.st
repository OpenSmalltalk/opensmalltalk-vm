Class {
	#name : #VMFFICallbacksTest,
	#superclass : #VMAbstractFFITest,
	#category : #VMMakerTests
}

{ #category : #'tests - callbacks' }
VMFFICallbacksTest >> doCallout: tfExternalFunction with: parametersArray [
	
	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray. 
	
	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.

]

{ #category : #'tests - callbacks' }
VMFFICallbacksTest >> testPrimitiveSameThreadCallbackInCalloutSuspendsActiveProcess [

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
VMFFICallbacksTest >> testPrimitiveSameThreadCallbackReturnKeepsAllOtherProcessesInReady [

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
VMFFICallbacksTest >> testPrimitiveSameThreadCallbackReturnResumesCalloutProcess [

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
VMFFICallbacksTest >> testPrimitiveSameThreadReentrantCallbackRestoresCalloutProcess [

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
