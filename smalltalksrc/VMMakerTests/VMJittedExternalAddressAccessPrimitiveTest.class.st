Class {
	#name : #VMJittedExternalAddressAccessPrimitiveTest,
	#superclass : #VMJittedByteArrayAccessPrimitiveTest,
	#category : #'VMMakerTests-JitTests'
}

{ #category : #utils }
VMJittedExternalAddressAccessPrimitiveTest >> newReceiver [
	"In this case the target receiver is a byteArray and the receiver to the primitive is an external address pointing to it"

	super newReceiver.
	
	receiver := memory newExternalAddressWithValue: targetReceiver + 8.

]

{ #category : #utils }
VMJittedExternalAddressAccessPrimitiveTest >> trailingName [

	^ 'ExternalAddress'
]
