Class {
	#name : #VMMockCogThreadManager,
	#superclass : #CogThreadManager,
	#category : #'VMMakerCompatibilityForPharo6-Tests'
}

{ #category : #simulation }
VMMockCogThreadManager >> ioWaitOnOSSemaphore: aSemaphorePtr [

	CAContinuation shift: [ :c | c ]
]
