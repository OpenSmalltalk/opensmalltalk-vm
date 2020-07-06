Class {
	#name : #VMFFICalloutTest,
	#superclass : #VMAbstractFFITest,
	#category : #VMMakerTests
}

{ #category : #'tests - callouts' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutMaintainsActiveProcess [

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
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningDoublePushSmallFloatInStack [
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
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningFloatPushSmallFloatInStack [

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
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningVoidPushesTheReceiver [

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
VMFFICalloutTest >> testPrimitiveSameThreadCalloutShouldKeepTheNewMethodVariable [

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
