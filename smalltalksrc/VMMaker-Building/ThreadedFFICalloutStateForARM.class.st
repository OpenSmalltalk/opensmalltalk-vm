Class {
	#name : #ThreadedFFICalloutStateForARM,
	#superclass : #ThreadedFFICalloutState,
	#instVars : [
		'integerRegisterIndex',
		'integerRegisters',
		'floatRegisterIndex',
		'floatRegisters'
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
						['integerRegisters']	-> [{#sqInt. '[', ThreadedARMFFIPlugin numIntRegArgs printString, ']'}].
						['floatRegisters']	-> [{#float. '[', ThreadedARMFFIPlugin numFloatRegArgs printString, ']'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> floatRegisterIndex [

	^ floatRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> floatRegisterIndex: anObject [

	^floatRegisterIndex := anObject
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> floatRegisters [

	^ floatRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> floatRegisters: anObject [

	^floatRegisters := anObject
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForARM >> initialize [
	super initialize.
	integerRegisterIndex := 0.
	floatRegisterIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: ThreadedARMFFIPlugin numIntRegArgs).
	floatRegisters := CArrayAccessor on: (Array new: ThreadedARMFFIPlugin numFloatRegArgs)
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> integerRegisterIndex [

	^ integerRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM >> integerRegisterIndex: anObject [

	^integerRegisterIndex := anObject
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
