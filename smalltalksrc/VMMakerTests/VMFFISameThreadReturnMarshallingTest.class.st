Class {
	#name : #VMFFISameThreadReturnMarshallingTest,
	#superclass : #VMFFIReturnMarshallingTest,
	#category : #VMMakerTests
}

{ #category : #'tests - marshalling return' }
VMFFISameThreadReturnMarshallingTest >> doTestCalloutWithReturnType: aLibFFIType returnValue: valueToReturn asserting: aBlock [

	| parametersArray tfExternalFunction |

	tfExternalFunction := self
		createExternalFunctionFor: [ valueToReturn ]
		withArgumentTypes: #()
		withReturnType: aLibFFIType.

	parametersArray := self newObjectWithSlots: 0.

	interpreter push: memory trueObject.
	interpreter push: tfExternalFunction.
	interpreter push: parametersArray.

	interpreter argumentCount: 2.
	interpreter primitiveSameThreadCallout.
	
	aBlock value
]

{ #category : #'tests - marshalling return' }
VMFFISameThreadReturnMarshallingTest >> testPrimitiveCalloutReturningVoidPushesTheReceiver [

	self 
		doTestCalloutWithReturnType: interpreter libFFI void
		returnValue: nil 
		asserting: [ self assert: interpreter stackTop equals: memory trueObject].
]
