Class {
	#name : #FullBlockClosure,
	#superclass : #BlockClosure,
	#type : #variable,
	#instVars : [
		'receiver'
	],
	#category : 'BytecodeSets-SistaV1'
}

{ #category : #private }
FullBlockClosure >> asContextWithSender: aContext [
	"Inner private support method for evaluation.  Do not use unless you know what you're doing."

	^(MethodContext newForMethod: self compiledBlock)
		setSender: aContext
		receiver: self receiver
		method: self compiledBlock
		closure: self
		startpc: self startpc;
		privRefresh
]

{ #category : #accessing }
FullBlockClosure >> compiledBlock [
	"To be able to inherit from BlockClosure"
	^ startpc
]

{ #category : #accessing }
FullBlockClosure >> home [
	^ outerContext ifNotNil: [ outerContext home ]
]

{ #category : #accessing }
FullBlockClosure >> method [
	^ self compiledBlock
]

{ #category : #accessing }
FullBlockClosure >> numTemps [
	^ self compiledBlock numTemps
]

{ #category : #accessing }
FullBlockClosure >> receiver [
	^ receiver
]

{ #category : #accessing }
FullBlockClosure >> startpc [
	^ self compiledBlock initialPC
]
