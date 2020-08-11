Class {
	#name : #VMMockScheduler,
	#superclass : #VMMockObject,
	#instVars : [
		'quiescentProcessLists',
		'activeProcess'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #accessing }
VMMockScheduler >> activeProcess [
	^ activeProcess
]

{ #category : #accessing }
VMMockScheduler >> activeProcess: anInteger [ 

	activeProcess := anInteger
]

{ #category : #accessing }
VMMockScheduler >> addProcess: aVMMockProcess atPriority: anInteger [ 

	(quiescentProcessLists at: anInteger) add: aVMMockProcess
]

{ #category : #initialization }
VMMockScheduler >> initialize [

	super initialize.
	quiescentProcessLists := (VMMockArray new: 5)
		objectMemory: objectMemory;
		yourself.
	1 to: quiescentProcessLists size do: [ :i |
			quiescentProcessLists
				at: i
				put: (VMLinkedList new
					objectMemory: objectMemory;
					yourself) ].
]
