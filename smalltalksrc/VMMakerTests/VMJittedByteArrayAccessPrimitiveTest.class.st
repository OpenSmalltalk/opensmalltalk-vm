Class {
	#name : #VMJittedByteArrayAccessPrimitiveTest,
	#superclass : #VMJittedPrimitivesTest,
	#category : #'VMMakerTests-JitTests'
}

{ #category : #tests }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt16IntoBytesStoresNegativeValue [

	| receiver |
	
	self wordSize = 4 ifTrue: [ ^ self skip ].
	
	self compile: [ cogit objectRepresentation genPrimitiveStoreInt16IntoBytes ].
	
	receiver := self new8BitIndexableOfSize: 10.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: -16r34). 
	
	self assert: (memory fetchByte: 0 ofObject: receiver) equals: 16rCC.
	self assert: (memory fetchByte: 1 ofObject: receiver) equals: 16rFF.	
]

{ #category : #tests }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreUInt16IntoBytesStoresNegativeValue [

	| receiver |
	
	self wordSize = 4 ifTrue: [ ^ self skip ].
	
	self compile: [ cogit objectRepresentation genPrimitiveStoreUInt16IntoBytes ].
	
	receiver := self new8BitIndexableOfSize: 10.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: 16r1234).
	
	self assert: (memory fetchByte: 0 ofObject: receiver) equals: 16r34.
	self assert: (memory fetchByte: 1 ofObject: receiver) equals: 16r12.	
]
