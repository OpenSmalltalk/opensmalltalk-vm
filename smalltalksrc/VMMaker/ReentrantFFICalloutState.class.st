Class {
	#name : #ReentrantFFICalloutState,
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
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ReentrantFFICalloutState class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ReentrantFFICalloutState struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['argVector']	-> [#'char *'].
						['currentArg']	-> [#'char *'].
						['limit']	-> [#'char *'].
						['ffiArgSpec']	-> [#'void *'].
						['stringArgs']	-> [{#'char *'. '[', ReentrantFFIPlugin maxNumArgs printString, ']'}] }
					otherwise:
						[#sqInt])]
]

{ #category : #translation }
ReentrantFFICalloutState class >> structTypeName [
	^'CalloutState' "Drop verbiage and platform specifics"
]

{ #category : #accessing }
ReentrantFFICalloutState >> argVector [
	"Answer the value of argVector"

	^ argVector
]

{ #category : #accessing }
ReentrantFFICalloutState >> argVector: anObject [
	"Set the value of argVector"

	^argVector := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> callFlags [
	"Answer the value of callFlags"

	^ callFlags
]

{ #category : #accessing }
ReentrantFFICalloutState >> callFlags: anObject [
	"Set the value of callFlags"

	^callFlags := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> currentArg [
	"Answer the value of currentArg"

	^ currentArg
]

{ #category : #accessing }
ReentrantFFICalloutState >> currentArg: anObject [
	"Set the value of currentArg"

	^currentArg := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiArgHeader [
	"Answer the value of ffiArgHeader"

	^ ffiArgHeader
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiArgHeader: anObject [
	"Set the value of ffiArgHeader"

	^ffiArgHeader := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiArgSpec [
	"Answer the value of ffiArgSpec"

	^ ffiArgSpec
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiArgSpec: anObject [
	"Set the value of ffiArgSpec"

	^ffiArgSpec := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiArgSpecSize [
	"Answer the value of ffiArgSpecSize"

	^ ffiArgSpecSize
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiArgSpecSize: anObject [
	"Set the value of ffiArgSpecSize"

	^ffiArgSpecSize := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiRetHeader [
	"Answer the value of ffiRetHeader"

	^ ffiRetHeader
]

{ #category : #accessing }
ReentrantFFICalloutState >> ffiRetHeader: anObject [
	"Set the value of ffiRetHeader"

	^ffiRetHeader := anObject
]

{ #category : #'initialize-release' }
ReentrantFFICalloutState >> initialize [
	<doNotGenerate>
	stringArgs := CArrayAccessor on: (Array new: ReentrantFFIPlugin maxNumArgs).
	stringArgIndex := 0.
	structReturnSize := 0
]

{ #category : #accessing }
ReentrantFFICalloutState >> limit [
	"Answer the value of limit"

	^ limit
]

{ #category : #accessing }
ReentrantFFICalloutState >> limit: anObject [
	"Set the value of limit"

	^limit := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> stringArgIndex [
	"Answer the value of stringArgIndex"

	^ stringArgIndex
]

{ #category : #accessing }
ReentrantFFICalloutState >> stringArgIndex: anObject [
	"Set the value of stringArgIndex"

	^stringArgIndex := anObject
]

{ #category : #accessing }
ReentrantFFICalloutState >> stringArgs [
	"Answer the value of stringArgs"

	^ stringArgs
]

{ #category : #accessing }
ReentrantFFICalloutState >> structReturnSize [
	"Answer the value of structReturnSize"

	^ structReturnSize
]

{ #category : #accessing }
ReentrantFFICalloutState >> structReturnSize: anObject [
	"Set the value of structReturnSize"

	^structReturnSize := anObject
]
