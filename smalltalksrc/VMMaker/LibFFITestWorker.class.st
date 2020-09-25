Class {
	#name : #LibFFITestWorker,
	#superclass : #Object,
	#instVars : [
		'tasks'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #accessing }
LibFFITestWorker >> asInteger [
	^ 16rFFFF1FFF
]

{ #category : #clearing }
LibFFITestWorker >> clear [
	
	tasks removeAll
]

{ #category : #'as yet unclassified' }
LibFFITestWorker >> dispatchCallout: aLibFFITestWorkerTask [ 

	tasks add: aLibFFITestWorkerTask
]

{ #category : #'as yet unclassified' }
LibFFITestWorker >> initialize [ 

	super initialize.
	tasks := OrderedCollection new
]

{ #category : #accessing }
LibFFITestWorker >> tasks [
	^ tasks
]
