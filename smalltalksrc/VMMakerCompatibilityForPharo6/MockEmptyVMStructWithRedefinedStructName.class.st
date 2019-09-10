Class {
	#name : #MockEmptyVMStructWithRedefinedStructName,
	#superclass : #MockEmptyVMStruct,
	#category : #'VMMakerCompatibilityForPharo6-Tests'
}

{ #category : #translation }
MockEmptyVMStructWithRedefinedStructName class >> structTypeName [

	^ 'RedefinedStruct'
]
