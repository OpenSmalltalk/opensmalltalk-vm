Class {
	#name : #VMJittedPrimitiveAtPutTest,
	#superclass : #VMJittedPrimitivesTest,
	#instVars : [
		'stop'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #running }
VMJittedPrimitiveAtPutTest >> setUp [

	super setUp.
	
	self setUpTrampolines.

	initialAddress := self
		compile: [ 
			cogit objectRepresentation genPrimitiveAtPut.
			stop := cogit Stop ]
		bytecodes: 10.
]

{ #category : #running }
VMJittedPrimitiveAtPutTest >> setUpTrampolines [ 

	super setUpTrampolines.
	
	cogit ceStoreCheckTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named: #ceStoreCheckTrampoline).

]

{ #category : #tests }
VMJittedPrimitiveAtPutTest >> testPrimitiveAtPut32bitIndexableWithLargeNumberShouldStoreValue [

	| integerArray offset expectedValue |
	"In 32bits it should fall through, as it will need to store a LargePositiveInteger"
	wordSize = 8 ifFalse: [ ^ self skip ].

	integerArray := self new32BitIndexableOfSize: 3.
	offset := 2.
	expectedValue := 16rFFFFFFFF.

	self
		prepareStackForSendReceiver: integerArray
		arguments: { memory integerObjectOf: offset. memory integerObjectOf: expectedValue }.

	machineSimulator baseRegisterValue: cogit varBaseAddress.

	self runUntilReturn.

	self
		assert: (memory fetchLong32: offset - 1 ofObject: integerArray)
		equals: expectedValue
]
