Class {
	#name : #VMFFISameThreadCalloutTest,
	#superclass : #VMAbstractFFITest,
	#category : #VMMakerTests
}

{ #category : #'tests - callouts' }
VMFFISameThreadCalloutTest >> testPrimitiveSameThreadCalloutMaintainsActiveProcess [

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
VMFFISameThreadCalloutTest >> testPrimitiveSameThreadCalloutShouldKeepTheNewMethodVariable [

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
