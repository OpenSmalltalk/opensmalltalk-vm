"
A ThreadedFFICalloutStateForARM64 is used to pass FFI parameters for foreign calls.

Instance Variables
	floatRegisterIndex:	Integer
	floatRegisters:		Array of SqInt [64 bit]
	integerRegisterIndex: Integer
	integerRegisters:	Array of Double

			
"
Class {
	#name : #ThreadedFFICalloutStateForARM64,
	#superclass : #ThreadedFFICalloutState,
	#instVars : [
		'integerRegisterIndex',
		'floatRegisterIndex',
		'integerRegisters',
		'floatRegisters'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedFFICalloutStateForARM64 class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ThreadedFFICalloutState struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [{#sqInt.   '[NumIntRegArgs]'   }].
						['floatRegisters']	-> [{#double. '[NumFloatRegArgs]'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> floatRegisterIndex [

	^ floatRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> floatRegisterIndex: anObject [

	^ floatRegisterIndex := anObject.
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> floatRegisters [

	^ floatRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> floatRegisters: anObject [

	^ floatRegisters := anObject.
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForARM64 >> initialize [
	super initialize.
	integerRegisterIndex := 0.
	floatRegisterIndex     := 0.
	resultAddress            := 0. "Only used for struct returns which do not fit in registers"
	integerRegisters := CArrayAccessor on: (Array new: ThreadedARM64FFIPlugin numIntRegArgs).
	floatRegisters     := CArrayAccessor on: (Array new: ThreadedARM64FFIPlugin numFloatRegArgs).

]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> integerRegisterIndex [

	^ integerRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> integerRegisterIndex: anObject [

	^ integerRegisterIndex := anObject.
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> integerRegisters [

	^ integerRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForARM64 >> integerRegisters: anObject [

	^ integerRegisters := anObject.
]
