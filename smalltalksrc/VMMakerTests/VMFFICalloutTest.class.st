Class {
	#name : #VMFFICalloutTest,
	#superclass : #VMAbstractFFITest,
	#category : #VMMakerTests
}

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> doTestCalloutWithReturnType: aLibFFIType returnValue: valueToReturn expectedSmalltalkValue: expectedValue [ 

	| parametersArray tfExternalFunction |

	tfExternalFunction := self
		createExternalFunctionFor: [ valueToReturn ]
		withArgumentTypes: #()
		withReturnType: aLibFFIType.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray.

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter primFailCode equals: 0.
	self assert: interpreter stackTop equals: expectedValue
]

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

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningDoublePushSmallFloatInStack [

	self
		doTestCalloutWithReturnType: interpreter libFFI double
		returnValue: 7.0
		expectedSmalltalkValue: (memory floatObjectOf: 7.0)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningFloatPushSmallFloatInStack [

	self
		doTestCalloutWithReturnType: interpreter libFFI float
		returnValue: 7.0
		expectedSmalltalkValue: (memory floatObjectOf: 7.0)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningPointerPushesAnExternalAddress [

	| parametersArray tfExternalFunction |

	tfExternalFunction := self
		createExternalFunctionFor: [ 17 ]
		withArgumentTypes: #()
		withReturnType: interpreter libFFI pointer.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory nilObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray.

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	self assert: interpreter primFailCode equals: 0.
	self assert: (memory fetchClassOfNonImm: interpreter stackTop) equals: memory classExternalAddress.
	self assert: (interpreter readAddress: interpreter stackTop) equals: 17
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningSINT16PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint16
		returnValue: INT16_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT16_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningSINT32PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint32
		returnValue: INT32_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT32_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningSINT64PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint64
		returnValue: INT64_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT64_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningSINT8PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint8
		returnValue: INT8_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT8_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningUINT16PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint16
		returnValue: INT16_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT16_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningUINT32PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint32
		returnValue: INT32_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT32_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningUINT64PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint64
		returnValue: INT64_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT64_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFICalloutTest >> testPrimitiveSameThreadCalloutReturningUINT8PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint8
		returnValue: INT8_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT8_MAX - 1)
]

{ #category : #'tests - marshalling return' }
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
