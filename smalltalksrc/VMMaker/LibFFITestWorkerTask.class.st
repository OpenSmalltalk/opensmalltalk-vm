Class {
	#name : #LibFFITestWorkerTask,
	#superclass : #Object,
	#instVars : [
		'externalFunction',
		'cif',
		'parameters',
		'returnHolder',
		'semaphoreIndex'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #accessing }
LibFFITestWorkerTask >> asInteger [
	
	^ 16rFF1FF
]

{ #category : #accessing }
LibFFITestWorkerTask >> cif: aLibFFICIF [ 
	cif := aLibFFICIF
]

{ #category : #accessing }
LibFFITestWorkerTask >> externalFunction: anInteger [ 
	externalFunction := anInteger
]

{ #category : #accessing }
LibFFITestWorkerTask >> parameters [
	^ parameters
]

{ #category : #accessing }
LibFFITestWorkerTask >> parameters: aCArrayAccessor [ 
	parameters := aCArrayAccessor
]

{ #category : #accessing }
LibFFITestWorkerTask >> returnHolder [
	^ returnHolder
]

{ #category : #accessing }
LibFFITestWorkerTask >> returnHolder: aCArrayAccessor [ 
	returnHolder := aCArrayAccessor
]

{ #category : #accessing }
LibFFITestWorkerTask >> semaphoreIndex: anInteger [ 
	semaphoreIndex := anInteger
]
