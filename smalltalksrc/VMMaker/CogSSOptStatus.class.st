Class {
	#name : #CogSSOptStatus,
	#superclass : #VMStructType,
	#instVars : [
		'isReceiverResultRegLive',
		'ssEntry'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogSSOptStatus class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogSSOptStatus struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn = 'ssEntry'
					ifTrue: [#'CogSimStackEntry *']
					ifFalse: [#sqInt])]
]

{ #category : #accessing }
CogSSOptStatus >> isReceiverResultRegLive [
	"Answer the value of isReceiverResultRegLive"

	^ isReceiverResultRegLive
]

{ #category : #accessing }
CogSSOptStatus >> isReceiverResultRegLive: anObject [
	"Set the value of isReceiverResultRegLive"

	^isReceiverResultRegLive := anObject
]

{ #category : #printing }
CogSSOptStatus >> printStateOn: aStream [
	<doNotGenerate>
	(isReceiverResultRegLive notNil
	 or: [ssEntry notNil]) ifTrue:
		[aStream
			nextPut: $(;
			print: isReceiverResultRegLive;
			space.
		ssEntry
			ifNil: [aStream nextPutAll: 'ssEntry is nil']
			ifNotNil: [ssEntry printStateOn: aStream].
		aStream nextPut: $)]
]

{ #category : #accessing }
CogSSOptStatus >> ssEntry [
	"Answer the value of ssEntry"

	^ ssEntry
]

{ #category : #accessing }
CogSSOptStatus >> ssEntry: anObject [
	"Set the value of ssEntry"

	^ssEntry := anObject
]
