Class {
	#name : #Project,
	#superclass : #Object,
	#category : #'VMMakerCompatibilityForPharo6-System'
}

{ #category : #accessing }
Project class >> current [

	^ self
]

{ #category : #accessing }
Project class >> restore [

	UIManager default restoreDisplay
]

{ #category : #accessing }
Project class >> uiProcess [

	^ UIManager default uiProcess
]
