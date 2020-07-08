Class {
	#name : #VMFFISameThreadArgumentMarshallingTest,
	#superclass : #VMFFIArgumentMarshallingTest,
	#category : #VMMakerTests
}

{ #category : #implementation }
VMFFISameThreadArgumentMarshallingTest >> doTestFuntionWithArgumentType: argumentType smalltalkValue: smalltalkValue expectedValue: expectedValue [

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

{ #category : #implementation }
VMFFISameThreadArgumentMarshallingTest >> doTestFuntionWithArgumentType: argumentType smalltalkValue: smalltalkValue failsWith: expectedErrorCode [

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
