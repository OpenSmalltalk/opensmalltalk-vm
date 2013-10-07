"
A task that suspends itself after each time it has been run to simulate waiting for data from an external device.

"
Class {
	#name : #RichDeviceTaskDataRecord,
	#superclass : #RichObject,
	#instVars : [
		'pending'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #accessing }
RichDeviceTaskDataRecord >> pending [
	^ pending
]

{ #category : #accessing }
RichDeviceTaskDataRecord >> pending: anObject [
	pending := anObject
]
