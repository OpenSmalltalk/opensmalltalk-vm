Class {
	#name : #ShootoutPair,
	#superclass : #Object,
	#instVars : [
		'partner',
		'me',
		'sema'
	],
	#category : #'CogBenchmarks-Shootout'
}

{ #category : #'instance creation' }
ShootoutPair class >> new [
   "Answer a newly created and initialized instance."
   ^super new initialize.
]

{ #category : #'instance creation' }
ShootoutPair class >> with: me [
   "Answer a newly created and initialized instance."
self halt.
   ^super new initialize me: me
]

{ #category : #'initialize-release' }
ShootoutPair >> initialize [
   "Initialize a newly created instance. This method must answer the receiver."

   partner := nil.
   me := nil.
   sema := Semaphore new.
   ^self
]

{ #category : #accessing }
ShootoutPair >> me [
   ^me
]

{ #category : #accessing }
ShootoutPair >> me: anObject [
   me := anObject
]

{ #category : #accessing }
ShootoutPair >> partner [
   ^partner
]

{ #category : #accessing }
ShootoutPair >> partner: anObject [
   partner := anObject
]

{ #category : #'initialize-release' }
ShootoutPair >> release [
partner:=nil.
]

{ #category : #'initialize-release' }
ShootoutPair >> signal [
   sema signal
]

{ #category : #'initialize-release' }
ShootoutPair >> wait [
   sema wait
]
