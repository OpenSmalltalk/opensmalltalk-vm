"
A task that manipulates work packets and then suspends itself.
"
Class {
	#name : #RichHandlerTaskDataRecord,
	#superclass : #RichObject,
	#instVars : [
		'workIn',
		'deviceIn'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #accessing }
RichHandlerTaskDataRecord >> deviceIn [
	^ deviceIn
]

{ #category : #accessing }
RichHandlerTaskDataRecord >> deviceIn: anObject [
	deviceIn := anObject
]

{ #category : #accessing }
RichHandlerTaskDataRecord >> deviceInAdd: packet [
    deviceIn := self append: packet head: deviceIn
]

{ #category : #accessing }
RichHandlerTaskDataRecord >> workIn [
	^ workIn
]

{ #category : #accessing }
RichHandlerTaskDataRecord >> workIn: anObject [
	workIn := anObject
]

{ #category : #accessing }
RichHandlerTaskDataRecord >> workInAdd: packet [
    workIn := self append: packet head: workIn
]
