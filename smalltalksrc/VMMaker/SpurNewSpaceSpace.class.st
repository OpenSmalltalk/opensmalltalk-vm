Class {
	#name : #SpurNewSpaceSpace,
	#superclass : #VMStructType,
	#instVars : [
		'start',
		'limit'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurNewSpaceSpace class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	self allInstVarNames do:
		[:ivn|
		(SpurMemoryManager isNonArgumentImplicitReceiverVariableName: ivn) ifFalse:
			[aBinaryBlock value: ivn value: #usqInt]]
]

{ #category : #accessing }
SpurNewSpaceSpace >> limit [
	^limit
]

{ #category : #accessing }
SpurNewSpaceSpace >> limit: n [
	limit := n
]

{ #category : #printing }
SpurNewSpaceSpace >> printOn: aStream [
	<doNotGenerate>
	super printOn: aStream.
	(start notNil and: [limit notNil]) ifTrue:
		[aStream nextPutAll: ' start: '; nextPutAll: start hex; nextPutAll: ' limit: '; nextPutAll: limit hex]
]

{ #category : #accessing }
SpurNewSpaceSpace >> size [
	<doNotGenerate>
	
	^ self limit - self start
]

{ #category : #accessing }
SpurNewSpaceSpace >> start [
	^start
]

{ #category : #accessing }
SpurNewSpaceSpace >> start: n [
	start := n
]
