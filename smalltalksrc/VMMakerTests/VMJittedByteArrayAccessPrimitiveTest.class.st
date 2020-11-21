Class {
	#name : #VMJittedByteArrayAccessPrimitiveTest,
	#superclass : #VMJittedPrimitivesTest,
	#instVars : [
		'receiver',
		'targetReceiver'
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

	({ 8. 16. 32. 64 } includes: bitSize) ifFalse: [ self fail ].

	bitSize = 8 ifTrue: [ 
		self
			assert: (memory fetchByte: 0 ofObject: targetReceiver)
			equals: (expectedValue twoComplementOfBitSize: bitSize) ].

	bitSize = 16 ifTrue: [ 
		self
			assert: (memory fetchShort16: 0 ofObject: targetReceiver)
			equals: (expectedValue twoComplementOfBitSize: bitSize) ].

	bitSize = 32 ifTrue: [ 
		self
			assert: (memory fetchLong32: 0 ofObject: targetReceiver)
			equals: (expectedValue twoComplementOfBitSize: bitSize) ].

	bitSize = 64 ifTrue: [ 
		self
			assert: (memory fetchLong64: 0 ofObject: targetReceiver)
			equals: (expectedValue twoComplementOfBitSize: bitSize) ].
		
	
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
	"In this case the target receiver is the same receiver"
	
	| size |
	size := 10.
	
	receiver := self new8BitIndexableOfSize: size.
	
	1 to: size do: [ :i | memory storeByte: i - 1 ofObject: receiver withValue: 16r90+i ].
	
	targetReceiver := receiver
]

{ #category : #utils }
VMJittedByteArrayAccessPrimitiveTest >> newReceiverWithValue: aValue ofBitSize: bitSize [ 

	| complementedValue |

	self newReceiver.

	complementedValue := aValue twoComplementOfBitSize: bitSize.

	bitSize = 8 ifTrue: [ 
		memory storeByte: 0 ofObject: targetReceiver withValue: complementedValue].	

	bitSize = 16 ifTrue: [ 
		memory storeShort16: 0 ofObject: targetReceiver withValue: complementedValue].

	bitSize = 32 ifTrue: [ 
		memory storeLong32: 0 ofObject: targetReceiver withValue: complementedValue].	

	bitSize = 64 ifTrue: [ 
		memory storeLong64: 0 ofObject: targetReceiver withValue: complementedValue ].	
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

{ #category : #'tests - load chars' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadChar16LoadsValue [

	| expectedValue |
	
	expectedValue := 16r1122.

	self genPrimitive: #LoadChar16.
	
	self newReceiverWithValue: expectedValue ofBitSize: 16.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory characterValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load chars' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadChar32LoadsValue [

	| expectedValue |
	
	expectedValue := 16r11223344.

	self genPrimitive: #LoadChar32.
	
	self newReceiverWithValue: expectedValue ofBitSize: 32.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory characterValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load chars' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadChar8LoadsValue [

	| expectedValue |
	
	expectedValue := 16r54.

	self genPrimitive: #LoadChar8.
	
	self newReceiverWithValue: expectedValue ofBitSize: 8.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory characterValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load floats' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadFloat32LoadsValue [

	| expectedValue |
	
	expectedValue := -1.1754942106924411e-38.

	self genPrimitive: #LoadFloat32.
	
	self newReceiverWithValue: expectedValue asIEEE32BitWord ofBitSize: 32.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load floats' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadFloat64LoadsBoxedValue [

	| expectedValue |
	
	expectedValue := -1.390671161566996e-309.

	self genPrimitive: #LoadFloat64.
	
	self newReceiverWithValue: expectedValue asIEEE64BitWord ofBitSize: 64.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue) 
	 	equals: expectedValue

]

{ #category : #'tests - load floats' }
VMJittedByteArrayAccessPrimitiveTest >> testLoadFloat64LoadsValue [

	| expectedValue |
	
	expectedValue := -1.1754942106924411e-38.

	self genPrimitive: #LoadFloat64.
	
	self newReceiverWithValue: expectedValue asIEEE64BitWord ofBitSize: 64.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0).
	
	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue) 
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

{ #category : #'tests - store booleans' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreBoolean8StoresFalse [

	self genPrimitive: #StoreBoolean8.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: self memory falseObject. 
	
	self assertEqualsTo: 0 bitSize: 8.

]

{ #category : #'tests - store booleans' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreBoolean8StoresTrue [

	self genPrimitive: #StoreBoolean8.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: self memory trueObject. 
	
	self assertEqualsTo: 1 bitSize: 8.

]

{ #category : #'tests - store chars' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreChar16StoresValue [

	| expectedValue |

	expectedValue := 16r1122.

	self genPrimitive: #StoreChar16.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory characterObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 16.

]

{ #category : #'tests - store chars' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreChar32StoresValue [

	| expectedValue |

	expectedValue := 16r11223344.

	self genPrimitive: #StoreChar32.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory characterObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 32.

]

{ #category : #'tests - store chars' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreChar8StoresValue [

	| expectedValue |

	expectedValue := 16r11.

	self genPrimitive: #StoreChar8.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory characterObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 8.

]

{ #category : #'tests - store floats' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreFloat32StoresValue [

	| expectedValue |
	expectedValue := -1.1754942106924411e-38.

	self genPrimitive: #StoreFloat32.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory floatObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue asIEEE32BitWord bitSize: 32.

]

{ #category : #'tests - store floats' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreFloat64StoresBoxedFloatValue [

	| expectedValue |
	expectedValue := -1.390671161566996e-309.

	self genPrimitive: #StoreFloat64.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory floatObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue asIEEE64BitWord bitSize: 64.

]

{ #category : #'tests - store floats' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreFloat64StoresValue [

	| expectedValue |
	expectedValue := -1.1754942106924411e-38.

	self genPrimitive: #StoreFloat64.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory floatObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue asIEEE64BitWord bitSize: 64.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt16StoresNegativeValue [

	| expectedValue |

	expectedValue := -16r1122.

	self genPrimitive: #StoreInt16.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 16.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt16StoresPositiveValue [

	| expectedValue |

	expectedValue := 16r1122.

	self genPrimitive: #StoreInt16.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 16.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt32StoresNegativeValue [

	| expectedValue |

	expectedValue := -16r11223344.

	self genPrimitive: #StoreInt32.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 32.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt32StoresPositiveValue [

	| expectedValue |

	expectedValue := 16r11223344.

	self genPrimitive: #StoreInt32.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 32.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt64StoresNegativeValue [

	| expectedValue |

	expectedValue := -16r0122334455667788.

	self genPrimitive: #StoreInt64.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 64.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt64StoresPositiveValue [

	| expectedValue |

	expectedValue := 16r0122334455667788.

	self genPrimitive: #StoreInt64.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 64.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt8StoresNegativeValue [

	| expectedValue |

	expectedValue := -16r11.

	self genPrimitive: #StoreInt8.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 8.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreInt8StoresPositiveValue [

	| expectedValue |

	expectedValue := 16r11.

	self genPrimitive: #StoreInt8.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 8.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStorePointerStoresValue [

	| expectedValue |

	expectedValue := 16r1122334455667788.

	self genPrimitive: #StorePointer.

	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (memory newExternalAddressWithValue: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 64.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreUInt16StoresValue [

	| expectedValue |

	expectedValue := 16r1122.

	self genPrimitive: #StoreUInt16.
	
	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 16.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreUInt32StoresValue [

	| expectedValue |

	expectedValue := 16r11223344.

	self genPrimitive: #StoreUInt32.
	
	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 32.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreUInt64StoresValue [

	| expectedValue |

	"LargeIntegers are handled by the fallback code"
	expectedValue := 16r0122334455667788.

	self genPrimitive: #StoreUInt64.
	
	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 64.

]

{ #category : #'tests - store integers' }
VMJittedByteArrayAccessPrimitiveTest >> testPrimitiveStoreUInt8StoresValue [

	| expectedValue |

	expectedValue := 16r11.

	self genPrimitive: #StoreUInt8.
	
	self newReceiver.
	
	self 
		executePrimitiveWithReceiver: receiver
		withArgument: (self memory integerObjectOf: 0)
		and: (self memory integerObjectOf: expectedValue). 
	
	self assertEqualsTo: expectedValue bitSize: 8.

]

{ #category : #utils }
VMJittedByteArrayAccessPrimitiveTest >> trailingName [

	^ 'Bytes'
]
