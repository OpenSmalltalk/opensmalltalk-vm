Class {
	#name : #ThreadedFFICalloutStateForARM,
	#superclass : #ThreadedFFICalloutState,
	#instVars : [
		'regIndex',
		'integerRegisters'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ThreadedFFICalloutStateForARM class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ReentrantFFICalloutState struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [{#sqInt. '[', ReentrantARMFFIPlugin numRegArgs printString, ']'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForARM >> initialize [
	super initialize.
	regIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: ThreadedARMFFIPlugin numRegArgs)
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> integerRegisters [
	"Answer the value of integerRegisters"

	^ integerRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> integerRegisters: anObject [
	"Set the value of integerRegisters"

	^integerRegisters := anObject
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> regIndex [
	"Answer the value of regIndex"

	^ regIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> regIndex: anObject [
	"Set the value of regIndex"

	^regIndex := anObject
]
