Class {
	#name : #ReentrantFFICalloutStateForARM,
	#superclass : #ReentrantFFICalloutState,
	#instVars : [
		'regIndex',
		'integerRegisters'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ReentrantFFICalloutStateForARM class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ReentrantFFICalloutState struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [#(#sqInt '[', ReentrantARMFFIPlugin numRegArgs printString, ']')] }
					otherwise:
						[#sqInt])]
]

{ #category : #'initialize-release' }
ReentrantFFICalloutStateForARM >> initialize [
	super initialize.
	regIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: ReentrantARMFFIPlugin numRegArgs)
]

{ #category : #accessing }
ReentrantFFICalloutStateForARM >> integerRegisters [
	"Answer the value of integerRegisters"

	^ integerRegisters
]

{ #category : #accessing }
ReentrantFFICalloutStateForARM >> integerRegisters: anObject [
	"Set the value of integerRegisters"

	^integerRegisters := anObject
]

{ #category : #accessing }
ReentrantFFICalloutStateForARM >> regIndex [
	"Answer the value of regIndex"

	^ regIndex
]

{ #category : #accessing }
ReentrantFFICalloutStateForARM >> regIndex: anObject [
	"Set the value of regIndex"

	^regIndex := anObject
]
