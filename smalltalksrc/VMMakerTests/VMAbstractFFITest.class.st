Class {
	#name : #VMAbstractFFITest,
	#superclass : #VMAbstractPrimitiveTest,
	#pools : [
		'LibFFIConstants'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMAbstractFFITest >> createExternalFunctionFor: aBlock withArgumentTypes: argumentTypes withReturnType: returnType [

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
VMAbstractFFITest >> createReturnFloatExternalFunctionFor: aBlock [

	^ self
		createExternalFunctionFor: aBlock
		withArgumentTypes: #()
		withReturnType: interpreter libFFI float
]

{ #category : #helpers }
VMAbstractFFITest >> createReturnFloatExternalFunctionFor: aBlock withArgumentTypes: argumentTypes [

	^ self
		createExternalFunctionFor: aBlock
		withArgumentTypes: argumentTypes
		withReturnType: interpreter libFFI float
]

{ #category : #helpers }
VMAbstractFFITest >> interpreterClass [
	
	^ VMTestMockInterpreter
]

{ #category : #helpers }
VMAbstractFFITest >> newExternalAddress: anInteger [

	| anExternalAddress |
	anExternalAddress := self
		newObjectWithSlots: (memory numSlotsForBytes: self wordSize)
		format: (memory byteFormatForNumBytes: self wordSize)
		classIndex: memory classExternalAddressIndex.
		
	memory storePointer: 0 ofObject: anExternalAddress withValue: anInteger.
	^ anExternalAddress
]

{ #category : #'as yet unclassified' }
VMAbstractFFITest >> newMethodWithBytecodes: aCollection [ 

	^ methodBuilder 
		newMethod;
		bytecodes: aCollection;
		buildMethod
]

{ #category : #helpers }
VMAbstractFFITest >> readyProcesses [
	
	| collection |
	collection := OrderedCollection new.
	interpreter processesInProcessListDo: [ :e | collection add: e ].
	^ collection
]
