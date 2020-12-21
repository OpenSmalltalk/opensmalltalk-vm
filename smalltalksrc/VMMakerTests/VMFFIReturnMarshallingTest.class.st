Class {
	#name : #VMFFIReturnMarshallingTest,
	#superclass : #VMAbstractFFITest,
	#category : #VMMakerTests
}

{ #category : #private }
VMFFIReturnMarshallingTest class >> isAbstract [ 

	^ self = VMFFIReturnMarshallingTest
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> doTestCalloutWithReturnType: aLibFFIType returnValue: valueToReturn asserting: aBlock [
	
	self subclassResponsibility
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> doTestCalloutWithReturnType: aLibFFIType returnValue: valueToReturn expectedSmalltalkValue: expectedValue [

	self
		doTestCalloutWithReturnType: aLibFFIType
		returnValue: valueToReturn
		asserting: [ 	
				self assert: interpreter primFailCode equals: 0.
				self assert: interpreter stackTop equals: expectedValue ].

]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningAnStructPushesAByteArray [

	| valueToReturn |

	valueToReturn := ByteArray new: 16. 
	valueToReturn doubleAt: 1 put: 1.0.
	valueToReturn doubleAt: 9 put: 2.0.

	self 
		doTestCalloutWithReturnType: (interpreter libFFI structWith: {interpreter libFFI double. interpreter libFFI double.}) 
		returnValue: valueToReturn asserting: [	| content |
				self assert: interpreter primFailCode equals: 0.
				self assert: (memory fetchClassOfNonImm: interpreter stackTop) equals: memory classByteArray.
				self assert: (memory numBytesOf: interpreter stackTop) equals: 16.
				
				content := memory cCoerce: (memory firstIndexableField: interpreter stackTop) to: #'double *'. 
				self assert: (content at: 0) equals: 1.0.
				self assert: (content at: 1) equals: 2.0].
		
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningDoublePushSmallFloatInStack [

	self
		doTestCalloutWithReturnType: interpreter libFFI double
		returnValue: 7.0
		asserting: [ 	
				self assert: interpreter primFailCode equals: 0.
				self assert: (memory floatValueOf: interpreter stackTop) equals: 7.0 ].

]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningFloatPushSmallFloatInStack [

	self
		doTestCalloutWithReturnType: interpreter libFFI float
		returnValue: 7.0
		asserting: [ 	
				self assert: interpreter primFailCode equals: 0.
				self assert: (memory floatValueOf: interpreter stackTop) equals: 7.0 ].

]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningPointerPushesAnExternalAddress [


	self 
		doTestCalloutWithReturnType: interpreter libFFI pointer
		returnValue: 17 
		asserting: [ 	
				self assert: interpreter primFailCode equals: 0.
				self assert: (memory fetchClassOfNonImm: interpreter stackTop) equals: memory classExternalAddress.
				self assert: (interpreter readAddress: interpreter stackTop) equals: 17].

]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningSINT16PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint16
		returnValue: INT16_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT16_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningSINT32PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint32
		returnValue: INT32_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT32_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningSINT64PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint64
		returnValue: INT64_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT64_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningSINT8PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI sint8
		returnValue: INT8_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT8_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningUINT16PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint16
		returnValue: INT16_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT16_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningUINT32PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint32
		returnValue: INT32_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT32_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningUINT64PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint64
		returnValue: INT64_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT64_MAX - 1)
]

{ #category : #'tests - marshalling return' }
VMFFIReturnMarshallingTest >> testPrimitiveCalloutReturningUINT8PushSmallInteger [

	self
		doTestCalloutWithReturnType: interpreter libFFI uint8
		returnValue: INT8_MAX - 1
		expectedSmalltalkValue: (memory integerObjectOf: INT8_MAX - 1)
]
