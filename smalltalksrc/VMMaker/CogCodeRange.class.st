Class {
	#name : #CogCodeRange,
	#superclass : #Interval,
	#instVars : [
		'startpc',
		'endpc',
		'cogMethod'
	],
	#category : 'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
CogCodeRange class >> from: start to: stop cogMethod: cogMethod startpc: startpc [
	^(super from: start to: stop)
		cogMethod: cogMethod;
		startpc: startpc;
		yourself
]

{ #category : #accessing }
CogCodeRange >> cogMethod [
	"Answer the value of cogMethod"

	^ cogMethod
]

{ #category : #accessing }
CogCodeRange >> cogMethod: anObject [
	"Set the value of cogMethod"

	cogMethod := anObject
]

{ #category : #accessing }
CogCodeRange >> endPC [
	"Answer the value of endpc"

	^ endpc
]

{ #category : #accessing }
CogCodeRange >> endPC: anObject [
	endpc := anObject
]

{ #category : #explorer }
CogCodeRange >> explorerContents [
	^nil
]

{ #category : #printing }
CogCodeRange >> printOn: aStream [
	aStream nextPut: $(.
	(startpc notNil and: [endpc notNil])
		ifTrue:
			[aStream
				nextPutAll: 'bcpcs: ';
				print: startpc;
				nextPutAll: '->';
				print: endpc]
		ifFalse:
			[aStream nextPutAll: 'startpc: '; print: startpc].
	aStream space.
	start storeOn: aStream base: 16.
	aStream nextPutAll: ' to: '.
	stop storeOn: aStream base: 16.
	step ~= 1 ifTrue: [aStream nextPutAll: ' by: '; print: step].
	aStream nextPut: $)
]

{ #category : #accessing }
CogCodeRange >> startpc [
	"Answer the value of startpc"

	^ startpc
]

{ #category : #accessing }
CogCodeRange >> startpc: anObject [
	"Set the value of startpc"

	startpc := anObject
]
