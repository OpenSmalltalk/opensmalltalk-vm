"
An idle task doesn't do any work itself but cycles control between the two device tasks.
"
Class {
	#name : #RichIdleTaskDataRecord,
	#superclass : #RichObject,
	#instVars : [
		'control',
		'count'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #accessing }
RichIdleTaskDataRecord >> control [
	^ control
]

{ #category : #accessing }
RichIdleTaskDataRecord >> control: anObject [
	control := anObject
]

{ #category : #accessing }
RichIdleTaskDataRecord >> count [
	^ count
]

{ #category : #accessing }
RichIdleTaskDataRecord >> count: anObject [
	count := anObject
]

{ #category : #initialize }
RichIdleTaskDataRecord >> initialize [
	control := 1.
    	count := 10000
]
