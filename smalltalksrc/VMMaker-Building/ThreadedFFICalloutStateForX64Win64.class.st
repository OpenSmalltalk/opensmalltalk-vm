"
A ThreadedFFICalloutStateForX64Win64 is a holder for the callout state maintained while marshalling an FFI call on an X64 (x86-64) system using the _WIN64 ABI.
"
Class {
	#name : #ThreadedFFICalloutStateForX64Win64,
	#superclass : #ThreadedFFICalloutStateForX64,
	#instVars : [
		'floatRegisterSignature'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #accessing }
ThreadedFFICalloutStateForX64Win64 class >> pluginClass [
	^ThreadedX64Win64FFIPlugin
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64Win64 >> floatRegisterSignature [
	^floatRegisterSignature
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64Win64 >> incrementFloatRegisterIndex [
	"There are only 4 args passed by register int or float.
	So we can't distinguish the float index from the integer index.
	So we have to increment both.
	
	Consequently, floatRegisterIndex cannot be used anymore to detect presence of float parameter.
	However, we set a signature bitmap indicating which register position is used to pass a float.
	
	IMPLEMENTATION NOTES:
	There are code generator hacks that bypass the accessors.
	So we cannot just redefine the method floatRegisterIndex as ^integerRegisterIndex.
	Instead we must maintain the two indices"

	floatRegisterSignature := floatRegisterSignature + (1 << floatRegisterIndex).
	^integerRegisterIndex := floatRegisterIndex := floatRegisterIndex + 1
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64Win64 >> incrementIntegerRegisterIndex [
	"There are only 4 args passed by register int or float.
	So we can't distinguish the float index from the integer index.
	So we have to increment both.
	
	IMPLEMENTATION NOTES:
	There are code generator hacks that bypass the accessors.
	So we cannot just redefine the method floatRegisterIndex as ^integerRegisterIndex.
	Instead we must maintain the two indices"

	^floatRegisterIndex := integerRegisterIndex := integerRegisterIndex + 1
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForX64Win64 >> initialize [
	super initialize.
	floatRegisterSignature := 0.
]
