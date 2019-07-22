Class {
	#name : #VMMockCogThreadManager,
	#superclass : #CogThreadManager,
	#category : #VMMakerTests
}

{ #category : #simulation }
VMMockCogThreadManager >> ioWaitOnOSSemaphore: aSemaphorePtr [

	CAContinuation shift: [ :c | c ]
]
