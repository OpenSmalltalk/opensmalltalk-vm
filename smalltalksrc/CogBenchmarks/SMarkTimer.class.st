"
A SMarkTimer is a simple timer.
A subclass can measure alternative metrics, or for instance use different time sources.

A subclass of SMarkRunner can then use the custom timer class by overriding SMarkRunner class >> #defaultTimer.
"
Class {
	#name : #SMarkTimer,
	#superclass : #Object,
	#instVars : [
		'startTime',
		'elapsedTime',
		'name'
	],
	#category : #'CogBenchmarks-SMark'
}

{ #category : #'instance creation' }
SMarkTimer class >> new: aName [
	| timer |
	
	timer := super new.
	timer name: aName.
	
	^timer
]

{ #category : #timing }
SMarkTimer >> currentMillis [

	^ Time millisecondClockValue
]

{ #category : #initialization }
SMarkTimer >> initialize [
	super initialize.
	elapsedTime := 0
]

{ #category : #accessing }
SMarkTimer >> name [
	^name
]

{ #category : #accessing }
SMarkTimer >> name: aString [
	name := aString 
]

{ #category : #timing }
SMarkTimer >> reset [
	startTime := 0.
	elapsedTime := 0.
]

{ #category : #timing }
SMarkTimer >> start [
	startTime := self currentMillis.
]

{ #category : #timing }
SMarkTimer >> stop [
	| elapsedInThisPeriod current |
	current := self currentMillis.
	
	elapsedInThisPeriod := Time milliseconds: current since: startTime.
	
	elapsedTime := elapsedTime + elapsedInThisPeriod.
]

{ #category : #accessing }
SMarkTimer >> totalTime [
	^elapsedTime
]
