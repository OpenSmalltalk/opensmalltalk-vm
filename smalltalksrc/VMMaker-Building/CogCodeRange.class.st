Class {
	#name : #CogCodeRange,
	#superclass : #Interval,
	#instVars : [
		'startpc',
		'cogMethod'
	],
	#category : #'VMMaker-JITSimulation'
}

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

{ #category : #printing }
CogCodeRange >> printOn: aStream [
	aStream nextPut: $(;
	 nextPutAll: 'pc: ';
	 print: startpc;
	 space.
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
