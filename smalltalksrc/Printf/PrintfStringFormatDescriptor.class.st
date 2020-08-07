Class {
	#name : #PrintfStringFormatDescriptor,
	#superclass : #PrintfFormatDescriptor,
	#category : #Printf
}

{ #category : #rendering }
PrintfStringFormatDescriptor >> applyOperator: object [
	^ object
]

{ #category : #printing }
PrintfStringFormatDescriptor >> printOn: aStream [
	super printOn: aStream.
	self printWidthOn: aStream.
	aStream nextPut: $s
]
