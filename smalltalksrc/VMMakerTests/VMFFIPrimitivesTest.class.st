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
VMFFIPrimitivesTest >> newExternalAddress: anInteger [

	| anExternalAddress |
	anExternalAddress := self
		newObjectWithSlots: (memory numSlotsForBytes: self wordSize)
		format: (memory byteFormatForNumBytes: self wordSize)
		classIndex: memory classExternalAddressIndex.
		
	memory storePointer: 0 ofObject: anExternalAddress withValue: anInteger.
	^ anExternalAddress
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
