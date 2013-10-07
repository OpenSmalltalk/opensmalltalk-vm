Class {
	#name : #ShootoutThread,
	#superclass : #Object,
	#instVars : [
		'name',
		'nextThread',
		'token',
		'semaphore',
		'done',
		'output'
	],
	#category : #'Cog-Benchmarks-Shootout'
}

{ #category : #'instance creation' }
ShootoutThread class >> named: anInteger next: aThread done: aSemaphore output: aStream [
   ^self new name: anInteger; nextThread: aThread; done: aSemaphore; output: aStream; fork 
]

{ #category : #'instance creation' }
ShootoutThread class >> new [
   ^self basicNew semaphore: Semaphore new 
]

{ #category : #accessing }
ShootoutThread >> done: aSemaphore [
   done := aSemaphore 
]

{ #category : #accessing }
ShootoutThread >> fork [
   [ self run ] fork 
]

{ #category : #accessing }
ShootoutThread >> name: anInteger [
   name := anInteger 
]

{ #category : #accessing }
ShootoutThread >> nextThread: aThread [
   nextThread := aThread 
]

{ #category : #accessing }
ShootoutThread >> output: anObject [
	"Set the value of output"

	output := anObject
]

{ #category : #accessing }
ShootoutThread >> run [
   [ self tokenNotDone ] whileTrue: [ nextThread takeToken: token - 1 ].
   output print: name.
   output name = 'stdout'
	ifTrue: [output nl]
	ifFalse: [output cr; flush].
   done signal 
]

{ #category : #accessing }
ShootoutThread >> semaphore: aSemaphore [
   semaphore := aSemaphore 
]

{ #category : #accessing }
ShootoutThread >> takeToken: x [
   token := x.
   semaphore signal 
]

{ #category : #accessing }
ShootoutThread >> tokenNotDone [
   semaphore wait.
   ^token > 0 
]
