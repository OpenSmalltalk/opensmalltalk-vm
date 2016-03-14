"
Instances of the receiver hold the per-thread state of a call-out.

long *argVector		pointer to the start of the alloca'ed argument marshalling area
long *currentArg		pointer to the position in argVector to write the current argument
long *limit			the limit of the argument marshalling area (for bounds checking)
structReturnSize		the size of the space allocated for the structure return, if any
callFlags			the value of the ExternalFunctionFlagsIndex field in the ExternalFunction being called
ffiArgSpec et al		type information for the current argument being marshalled
stringArgIndex		the count of temporary strings used for marshalling Smalltalk strings to character strings.
stringArgs			pointers to the temporary strings used for marshalling Smalltalk strings to character strings.
"
Class {
	#name : #ThreadedFFICalloutState,
	#superclass : #VMStructType,
	#instVars : [
		'argVector',
		'currentArg',
		'limit',
		'structReturnSize',
		'callFlags',
		'ffiArgSpec',
		'ffiArgSpecSize',
		'ffiArgHeader',
		'ffiRetHeader',
		'stringArgIndex',
		'stringArgs'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedFFICalloutState class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ThreadedFFICalloutState struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['argVector']	-> [#'char *'].
						['currentArg']	-> [#'char *'].
						['limit']			-> [#'char *'].
						['ffiArgSpec']	-> [#'void *'].
						['stringArgs']	-> [{#'char *'. '[MaxNumArgs]'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #translation }
ThreadedFFICalloutState class >> structTypeName [
	^'CalloutState' "Drop verbiage and platform specifics"
]

{ #category : #accessing }
ThreadedFFICalloutState >> argVector [
	"Answer the value of argVector"

	^ argVector
]

{ #category : #accessing }
ThreadedFFICalloutState >> argVector: anObject [
	"Set the value of argVector"

	^argVector := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> callFlags [
	"Answer the value of callFlags"

	^ callFlags
]

{ #category : #accessing }
ThreadedFFICalloutState >> callFlags: anObject [
	"Set the value of callFlags"

	^callFlags := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> currentArg [
	"Answer the value of currentArg"

	^ currentArg
]

{ #category : #accessing }
ThreadedFFICalloutState >> currentArg: anObject [
	"Set the value of currentArg"

	^currentArg := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiArgHeader [
	"Answer the value of ffiArgHeader"

	^ ffiArgHeader
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiArgHeader: anObject [
	"Set the value of ffiArgHeader"

	^ffiArgHeader := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiArgSpec [
	"Answer the value of ffiArgSpec"

	^ ffiArgSpec
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiArgSpec: anObject [
	"Set the value of ffiArgSpec"

	^ffiArgSpec := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiArgSpecSize [
	"Answer the value of ffiArgSpecSize"

	^ ffiArgSpecSize
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiArgSpecSize: anObject [
	"Set the value of ffiArgSpecSize"

	^ffiArgSpecSize := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiRetHeader [
	"Answer the value of ffiRetHeader"

	^ ffiRetHeader
]

{ #category : #accessing }
ThreadedFFICalloutState >> ffiRetHeader: anObject [
	"Set the value of ffiRetHeader"

	^ffiRetHeader := anObject
]

{ #category : #'initialize-release' }
ThreadedFFICalloutState >> initialize [
	<doNotGenerate>
	stringArgs := CArrayAccessor on: (Array new: ThreadedFFIPlugin maxNumArgs).
	stringArgIndex := 0.
	structReturnSize := 0
]

{ #category : #accessing }
ThreadedFFICalloutState >> limit [
	"Answer the value of limit"

	^ limit
]

{ #category : #accessing }
ThreadedFFICalloutState >> limit: anObject [
	"Set the value of limit"

	^limit := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> stringArgIndex [
	"Answer the value of stringArgIndex"

	^ stringArgIndex
]

{ #category : #accessing }
ThreadedFFICalloutState >> stringArgIndex: anObject [
	"Set the value of stringArgIndex"

	^stringArgIndex := anObject
]

{ #category : #accessing }
ThreadedFFICalloutState >> stringArgs [
	"Answer the value of stringArgs"

	^ stringArgs
]

{ #category : #accessing }
ThreadedFFICalloutState >> structReturnSize [
	"Answer the value of structReturnSize"

	^ structReturnSize
]

{ #category : #accessing }
ThreadedFFICalloutState >> structReturnSize: anObject [
	"Set the value of structReturnSize"

	^structReturnSize := anObject
]
