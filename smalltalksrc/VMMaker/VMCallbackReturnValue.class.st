"
A VMCallbackReturnValue supports legacy Alien callbacks.
"
Class {
	#name : #VMCallbackReturnValue,
	#superclass : #VMStructType,
	#instVars : [
		'type',
		'pad',
		'crvrvs'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
VMCallbackReturnValue class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"Define a CallbackContext, the argument to sendInvokeCallbackContext:
	 self typedef"

	| rvsType |
	VMCallbackContext instVarNamesAndTypesForTranslationDo:
		[:ivname :type| ivname = 'rvs' ifTrue: [rvsType := type]].
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn = 'crvrvs'
					ifTrue: [rvsType]
					ifFalse: [#int])]
]

{ #category : #accessing }
VMCallbackReturnValue >> crvrvs [
	^crvrvs
]

{ #category : #accessing }
VMCallbackReturnValue >> crvrvs: anObject [
	^crvrvs := anObject
]

{ #category : #accessing }
VMCallbackReturnValue >> type [
	"Answer the value of type"

	^ type
]

{ #category : #accessing }
VMCallbackReturnValue >> type: anObject [
	"Set the value of type"

	^type := anObject
]
