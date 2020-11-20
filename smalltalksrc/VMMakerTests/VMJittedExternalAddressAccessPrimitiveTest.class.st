Class {
	#name : #VMJittedExternalAddressAccessPrimitiveTest,
	#superclass : #VMJittedByteArrayAccessPrimitiveTest,
	#instVars : [
		'realData'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #utils }
VMJittedExternalAddressAccessPrimitiveTest >> assertEqualsTo: expectedValue bitSize: bitSize [

	bitSize ~= 16 ifTrue: [ self error ].
	
	self assert: (memory fetchShort16: 0 ofObject: realData) equals: (expectedValue twoComplementOfBitSize: bitSize)
]

{ #category : #utils }
VMJittedExternalAddressAccessPrimitiveTest >> newReceiver [

	realData := self new8BitIndexableOfSize: 10.
	receiver := memory newExternalAddressWithValue: realData + 8.

]

{ #category : #utils }
VMJittedExternalAddressAccessPrimitiveTest >> newReceiverWithValue: aValue ofBitSize: bitSize [ 

	| complementedValue |

	self newReceiver.
	
	complementedValue := aValue twoComplementOfBitSize: bitSize.

	bitSize = 8 ifTrue: [ 
		memory storeByte: 0 ofObject: realData withValue: complementedValue].	

	bitSize = 16 ifTrue: [ 
		memory storeShort16: 0 ofObject: realData withValue: complementedValue].	

	bitSize = 32 ifTrue: [ 
		memory storeLong32: 0 ofObject: realData withValue: complementedValue].	

	bitSize = 64 ifTrue: [ 
		memory storeLong64: 0 ofObject: realData withValue: complementedValue ].	


]

{ #category : #utils }
VMJittedExternalAddressAccessPrimitiveTest >> trailingName [

	^ 'ExternalAddress'
]
