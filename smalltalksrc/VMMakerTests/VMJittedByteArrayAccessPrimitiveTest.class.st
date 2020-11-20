Class {
	#name : #VMJittedByteArrayAccessPrimitiveTest,
	#superclass : #VMJittedPrimitivesTest,
	#instVars : [
		'receiver'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'building suites' }
VMJittedByteArrayAccessPrimitiveTest class >> testParameters [

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'aarch64'. #wordSize -> 8};
		addCase: { #ISA -> #'X64'. #wordSize -> 8};
		yourself
]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> assertEqualsTo: expectedValue bitSize: bitSize [

	bitSize ~= 16 ifTrue: [ self error ].
	
	self assert: (memory fetchShort16: 0 ofObject: receiver) equals: (expectedValue twoComplementOfBitSize: bitSize)
]

{ #category : #utils }
VMJittedByteArrayAccessPrimitiveTest >> genPrimitive: aString [ 

	| endPart |
	endPart := (aString beginsWith: 'Load') ifTrue: [ 'From' ] ifFalse: [ 'Into' ].
	endPart := endPart , self trailingName.

	self compile: [ cogit objectRepresentation 
			perform: ('genPrimitive', aString, endPart) asSymbol ].

]

{ #category : #utils }
VMJittedByteArrayAccessPrimitiveTest >> newReceiver [
	receiver := self new8BitIndexableOfSize: 10.

]

{ #category : #utils }
VMJittedByteArrayAccessPrimitiveTest >> newReceiverWithValue: aValue ofBitSize: bitSize [ 

	| complementedValue |

	self newReceiver.

	complementedValue := aValue twoComplementOfBitSize: bitSize.

	bitSize = 8 ifTrue: [ 
		memory storeByte: 0 ofObject: receiver withValue: complementedValue].	

	bitSize = 16 ifTrue: [ 
		memory storeShort16: 0 ofObject: receiver withValue: complementedValue].

	bitSize = 32 ifTrue: [ 
		memory storeLong32: 0 ofObject: receiver withValue: complementedValue].	

	bitSize = 64 ifTrue: [ 
		memory storeLong64: 0 ofObject: receiver withValue: complementedValue ].	
]

{ #category : #'tests - load booleans' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadBoolean8LoadsFalse [

	| expectedValue |
	
	expectedValue := memory falseObject.

	self genPrimitive: #LoadBoolean8.
	
	self newReceiverWithValue: 0 ofBitSize: 8.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: machineSimulator receiverRegisterValue 
	 	equals: expectedValue

]

{ #category : #'tests - load booleans' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadBoolean8LoadsTrue [

	| expectedValue |
	
	expectedValue := memory trueObject.
	
	self genPrimitive: #LoadBoolean8.
	
	self newReceiverWithValue: 1 ofBitSize: 8.	

	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: machineSimulator receiverRegisterValue 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt16LoadsNegativeValue [

	| expectedValue |
	
	expectedValue := -16r1234.

	self genPrimitive: #LoadInt16.

	self newReceiverWithValue: expectedValue ofBitSize: 16.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt16LoadsPositiveValue [

	| expectedValue |
	
	expectedValue := 16r1234.
	
	self genPrimitive: #LoadInt16.
	
	self newReceiverWithValue: expectedValue ofBitSize: 16.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
		equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt32LoadsNegativeValue [

	| expectedValue |
	
	expectedValue := -16r12345678.
	
	self genPrimitive: #LoadInt32.
	
	self newReceiverWithValue: expectedValue ofBitSize: 32.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt32LoadsPositiveValue [

	| expectedValue |
	
	expectedValue := 16r12345678.
	
	self genPrimitive: #LoadInt32.
	
	self newReceiverWithValue: expectedValue ofBitSize: 32.	

	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt64LoadsNegativeValue [

	| expectedValue |
	
	expectedValue := -16r34567812345678.
	
	self genPrimitive: #LoadInt64.
	
	self newReceiverWithValue: expectedValue ofBitSize: 64.	

	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt64LoadsPositiveValue [

	| expectedValue |
	
	expectedValue := 16r34567812345678.
	
	self genPrimitive: #LoadInt64.
	
	self newReceiverWithValue: expectedValue ofBitSize: 64.	
			
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt8LoadsNegativeValue [

	| expectedValue |
	
	expectedValue := -16r12.
	
	self genPrimitive: #LoadInt8.
	
	self newReceiverWithValue: expectedValue ofBitSize: 8.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadInt8LoadsPositiveValue [

	| expectedValue |
	
	expectedValue := 16r12.
	
	self genPrimitive: #LoadInt8.
	
	self newReceiverWithValue: expectedValue ofBitSize: 8.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadPointerLoadsValue [

	| expectedValue |
	
	expectedValue := 16r0234567812345678.
	
	self genPrimitive: #LoadPointer.
	
	self newReceiverWithValue: expectedValue ofBitSize: (self wordSize * 8).	
		
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (interpreter readAddress: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadUInt16LoadsValue [

	| expectedValue |
	
	expectedValue := 16r1234.
	
	self genPrimitive: #LoadUInt16.
	
	self newReceiverWithValue: expectedValue ofBitSize: 16.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadUInt32LoadsValue [

	| expectedValue |
	
	expectedValue := 16r12345678.
	
	self genPrimitive: #LoadUInt32.
	
	self newReceiverWithValue: expectedValue ofBitSize: 32.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadUInt64LoadsValue [

	| expectedValue |
	
	expectedValue := 16r0234567812345678.
	
	self genPrimitive: #LoadUInt64.
	
	self newReceiverWithValue: expectedValue ofBitSize: 64.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveLoadUInt8LoadsValue [

	| expectedValue |
	
	expectedValue := 16r12.
	
	self genPrimitive: #LoadUInt8.
	
	self newReceiverWithValue: expectedValue ofBitSize: 8.	
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt16IntoBytesStoresNegativeValue [

	self genPrimitive: #StoreInt16.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: -16r34). 
	
	self assertEqualsTo: -16r34 bitSize: 16.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreUInt16IntoBytesStoresValue [

	self genPrimitive: #StoreUInt16.
	
	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: 16r34).
	
	self assertEqualsTo: 16r34 bitSize: 16.

]

{ #category : #utils }
VMJittedByteArrayAccessPrimitiveTest >> trailingName [

	^ 'Bytes'
]
