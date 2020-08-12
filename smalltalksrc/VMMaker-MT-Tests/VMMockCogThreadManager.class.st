Class {
	#name : #VMMockCogThreadManager,
	#superclass : #CogThreadManager,
	#category : #'VMMaker-MT-Tests'
}

{ #category : #simulation }
VMMockCogThreadManager >> ioWaitOnOSSemaphore: aSemaphorePtr [

	CAContinuation shift: [ :c | c ]
]
