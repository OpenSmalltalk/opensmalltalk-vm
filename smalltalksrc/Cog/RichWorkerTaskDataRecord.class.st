"
A task that manipulates work packets.
"
Class {
	#name : #RichWorkerTaskDataRecord,
	#superclass : #RichObject,
	#instVars : [
		'destination',
		'count'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #accessing }
RichWorkerTaskDataRecord >> count [
	^ count
]

{ #category : #accessing }
RichWorkerTaskDataRecord >> count: anObject [
	count := anObject
]

{ #category : #accessing }
RichWorkerTaskDataRecord >> destination [
	^ destination
]

{ #category : #accessing }
RichWorkerTaskDataRecord >> destination: anObject [
	destination := anObject
]

{ #category : #'as yet unclassified' }
RichWorkerTaskDataRecord >> initialize [
    destination := HandlerA.
    count := 0 
]
