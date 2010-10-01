Class {
	#name : #ReentrantFFICalloutStateForPPC,
	#superclass : #ReentrantFFICalloutState,
	#instVars : [
		'regIndex',
		'integerRegisters',
		'floatRegisters'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ReentrantFFICalloutStateForPPC class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ReentrantFFICalloutState struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [{#sqInt. '[', ReentrantPPCBEFFIPlugin numRegArgs printString, ']'}].
						['floatRegisters']		-> [{#double. '[', ReentrantPPCBEFFIPlugin numRegArgs printString, ']'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
ReentrantFFICalloutStateForPPC >> floatRegisters [
	"Answer the value of floatRegisters"

	^ floatRegisters
]

{ #category : #'initialize-release' }
ReentrantFFICalloutStateForPPC >> initialize [
	super initialize.
	regIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: ReentrantPPCBEFFIPlugin numRegArgs).
	floatRegisters := CArrayAccessor on: (Array new: ReentrantPPCBEFFIPlugin numRegArgs)
]

{ #category : #accessing }
ReentrantFFICalloutStateForPPC >> integerRegisters [
	"Answer the value of integerRegisters"

	^ integerRegisters
]

{ #category : #accessing }
ReentrantFFICalloutStateForPPC >> regIndex [
	"Answer the value of regIndex"

	^ regIndex
]

{ #category : #accessing }
ReentrantFFICalloutStateForPPC >> regIndex: anObject [
	"Set the value of regIndex"

	^regIndex := anObject
]
