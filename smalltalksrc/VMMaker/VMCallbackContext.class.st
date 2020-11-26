Class {
	#name : #VMCallbackContext,
	#superclass : #VMStructType,
	#instVars : [
		'thunkp',
		'stackp',
		'intregargsp',
		'floatregargsp',
		'savedCStackPointer',
		'savedCFramePointer',
		'rvs',
		'savedPrimFunctionPointer',
		'trampoline',
		'savedReenterInterpreter'
	],
	#category : #'VMMaker-Support'
}

{ #category : #translation }
VMCallbackContext class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"Define a CallbackContext, the argument to sendInvokeCallbackContext:
	 self typedef"

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['stackp']				-> [#'sqIntptr_t *'].
						['intregargsp']			-> [#'sqIntptr_t *'].
						['floatregargsp']		-> [#'double *'].
						['rvs']					-> [
							'union {
								sqIntptr_t valword;
								struct { int low, high; } valleint64;
								struct { int high, low; } valbeint64;
								double valflt64;
								struct { void *addr; sqIntptr_t size; } valstruct;
							}'].
						['trampoline']				-> [#'jmp_buf'].
						['savedReenterInterpreter']	-> [#'jmp_buf']}
						otherwise: [#'void *'])]
]

{ #category : #translation }
VMCallbackContext class >> needsTypeTag [
	"This allows sqVirtualMachine.h to declare VMCallbackContext  as an
	 opaque type avoiding everyone including setjmp.h & vmCallback.h"
	^true
]

{ #category : #translation }
VMCallbackContext class >> printTypedefOn: aStream [
	super printTypedefOn: aStream.
	aStream
		cr;
		nextPutAll: '/* The callback return type codes */'; cr;
		nextPutAll: '#define retword 1'; cr;
		nextPutAll: '#define retword64 2'; cr;
		nextPutAll: '#define retdouble 3'; cr;
		nextPutAll: '#define retstruct 4'; cr;
		cr
]

{ #category : #asserting }
VMCallbackContext class >> shouldBeGenerated [

	^ false
]

{ #category : #accessing }
VMCallbackContext >> floatregargsp [
	"Answer the value of floatregargsp"

	^ floatregargsp
]

{ #category : #accessing }
VMCallbackContext >> floatregargsp: anObject [
	"Set the value of floatregargsp"

	^floatregargsp := anObject
]

{ #category : #accessing }
VMCallbackContext >> intregargsp [
	"Answer the value of intregargsp"

	^ intregargsp
]

{ #category : #accessing }
VMCallbackContext >> intregargsp: anObject [
	"Set the value of intregargsp"

	^intregargsp := anObject
]

{ #category : #accessing }
VMCallbackContext >> rvs [
	"Answer the value of rvs"

	^ rvs
]

{ #category : #accessing }
VMCallbackContext >> rvs: anObject [
	"Set the value of rvs"

	^rvs := anObject
]

{ #category : #accessing }
VMCallbackContext >> savedCFramePointer [
	"Answer the value of savedCFramePointer"

	^ savedCFramePointer
]

{ #category : #accessing }
VMCallbackContext >> savedCFramePointer: anObject [
	"Set the value of savedCFramePointer"

	^savedCFramePointer := anObject
]

{ #category : #accessing }
VMCallbackContext >> savedCStackPointer [
	"Answer the value of savedCStackPointer"

	^ savedCStackPointer
]

{ #category : #accessing }
VMCallbackContext >> savedCStackPointer: anObject [
	"Set the value of savedCStackPointer"

	^savedCStackPointer := anObject
]

{ #category : #accessing }
VMCallbackContext >> savedPrimFunctionPointer [
	
	^ savedPrimFunctionPointer

]

{ #category : #accessing }
VMCallbackContext >> savedPrimFunctionPointer: anObject [
	
	^ savedPrimFunctionPointer := anObject.

]

{ #category : #accessing }
VMCallbackContext >> savedReenterInterpreter [
	"Answer the value of savedReenterInterpreter"

	^ savedReenterInterpreter
]

{ #category : #accessing }
VMCallbackContext >> savedReenterInterpreter: anObject [
	"Set the value of savedReenterInterpreter"

	^savedReenterInterpreter := anObject
]

{ #category : #accessing }
VMCallbackContext >> stackp [
	"Answer the value of stackp"

	^ stackp
]

{ #category : #accessing }
VMCallbackContext >> stackp: anObject [
	"Set the value of stackp"

	^stackp := anObject
]

{ #category : #accessing }
VMCallbackContext >> thunkp [
	"Answer the value of thunkp"

	^ thunkp
]

{ #category : #accessing }
VMCallbackContext >> thunkp: anObject [
	"Set the value of thunkp"

	^thunkp := anObject
]

{ #category : #accessing }
VMCallbackContext >> trampoline [
	"Answer the value of trampoline"

	^ trampoline
]

{ #category : #accessing }
VMCallbackContext >> trampoline: anObject [
	"Set the value of trampoline"

	^trampoline := anObject
]
