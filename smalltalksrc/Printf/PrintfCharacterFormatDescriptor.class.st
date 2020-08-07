Class {
	#name : #PrintfCharacterFormatDescriptor,
	#superclass : #PrintfFormatDescriptor,
	#category : #Printf
}

{ #category : #rendering }
PrintfCharacterFormatDescriptor >> applyOperator: object [
	^ String with: object asCharacter
]

{ #category : #printing }
PrintfCharacterFormatDescriptor >> printOn: aStream [
	super printOn: aStream.
	self printWidthOn: aStream.
	aStream nextPut: $c
]
