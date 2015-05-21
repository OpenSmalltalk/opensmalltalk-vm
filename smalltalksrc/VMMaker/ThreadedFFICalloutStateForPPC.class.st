Class {
	#name : #ThreadedFFICalloutStateForPPC,
	#superclass : #ThreadedFFICalloutState,
	#instVars : [
		'registerIndex',
		'integerRegisters',
		'floatRegisters'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ThreadedFFICalloutStateForPPC class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ReentrantFFICalloutState struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [{#sqInt. '[', ThreadedPPCBEFFIPlugin numRegArgs printString, ']'}].
						['floatRegisters']		-> [{#double. '[', ThreadedPPCBEFFIPlugin numRegArgs printString, ']'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
ThreadedFFICalloutStateForPPC >> floatRegisters [
	"Answer the value of floatRegisters"

	^ floatRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForPPC >> floatRegisters: anObject [

	^floatRegisters := anObject
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForPPC >> initialize [
	super initialize.
	registerIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: ThreadedPPCBEFFIPlugin numRegArgs).
	floatRegisters := CArrayAccessor on: (Array new: ThreadedPPCBEFFIPlugin numRegArgs)
]

{ #category : #accessing }
ThreadedFFICalloutStateForPPC >> integerRegisters [
	"Answer the value of integerRegisters"

	^ integerRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForPPC >> integerRegisters: anObject [

	^integerRegisters := anObject
]

{ #category : #accessing }
ThreadedFFICalloutStateForPPC >> registerIndex [

	^ registerIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForPPC >> registerIndex: anObject [

	^registerIndex := anObject
]
