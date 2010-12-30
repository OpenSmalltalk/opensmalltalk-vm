Class {
	#name : #CogSSBytecodeFixup,
	#superclass : #CogBytecodeFixup,
	#instVars : [
		'simStackPtr',
		'simSpillBase',
		'mergeBase',
		'optStatus'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'simulation support' }
CogSSBytecodeFixup >> asUnsignedInteger [
	<doNotGenerate>
	^self
]

{ #category : #accessing }
CogSSBytecodeFixup >> mergeBase [
	"Answer the value of mergeBase"

	^ mergeBase
]

{ #category : #accessing }
CogSSBytecodeFixup >> mergeBase: anObject [
	"Set the value of mergeBase"

	^mergeBase := anObject
]

{ #category : #accessing }
CogSSBytecodeFixup >> optStatus [
	"Answer the value of optStatus"

	^ optStatus
]

{ #category : #accessing }
CogSSBytecodeFixup >> optStatus: anObject [
	"Set the value of optStatus"

	^optStatus := anObject
]

{ #category : #'debug printing' }
CogSSBytecodeFixup >> printStateOn: aStream [
	<doNotGenerate>
	(targetInstruction isNil and: [simStackPtr isNil]) ifTrue:
		[^self].
	aStream space; nextPut: $(.
	targetInstruction ifNotNil:
		[aStream space; print: targetInstruction].
	simStackPtr ifNotNil:
		[aStream space; print: simStackPtr].
	aStream nextPut: $)
]

{ #category : #accessing }
CogSSBytecodeFixup >> simSpillBase [
	"Answer the value of simSpillBase"

	^ simSpillBase
]

{ #category : #accessing }
CogSSBytecodeFixup >> simSpillBase: anObject [
	"Set the value of simSpillBase"

	^simSpillBase := anObject
]

{ #category : #accessing }
CogSSBytecodeFixup >> simStackPtr [
	"Answer the value of simStackPtr"

	^ simStackPtr
]

{ #category : #accessing }
CogSSBytecodeFixup >> simStackPtr: anObject [
	"Set the value of simStackPtr"

	^simStackPtr := anObject
]
