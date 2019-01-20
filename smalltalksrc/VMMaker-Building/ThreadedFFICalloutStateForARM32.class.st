Class {
	#name : #ThreadedFFICalloutStateForARM32,
	#superclass : #ThreadedFFICalloutState,
	#instVars : [
		'integerRegisterIndex',
		'integerRegisters',
		'floatRegisterIndex',
		'backfillFloatRegisterIndex',
		'floatRegisters'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedFFICalloutStateForARM32 class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ThreadedFFICalloutState struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [{#sqInt. '[NumIntRegArgs]'}].
						['floatRegisters']	-> [{#float. '[NumFloatRegArgs]'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> backfillFloatRegisterIndex [

	^ backfillFloatRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> backfillFloatRegisterIndex: anObject [

	^backfillFloatRegisterIndex := anObject
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> floatRegisterIndex [

	^ floatRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> floatRegisterIndex: anObject [

	^floatRegisterIndex := anObject
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> floatRegisters [

	^ floatRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> floatRegisters: anObject [

	^floatRegisters := anObject
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForARM32 >> initialize [
	super initialize.
	integerRegisterIndex := 0.
	floatRegisterIndex := 0.
	backfillFloatRegisterIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: ThreadedARMFFIPlugin numIntRegArgs).
	floatRegisters := CArrayAccessor on: (Array new: ThreadedARMFFIPlugin numFloatRegArgs)
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> integerRegisterIndex [

	^ integerRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> integerRegisterIndex: anObject [

	^integerRegisterIndex := anObject
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> integerRegisters [
	"Answer the value of integerRegisters"

	^ integerRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM32 >> integerRegisters: anObject [
	"Set the value of integerRegisters"

	^integerRegisters := anObject
]
