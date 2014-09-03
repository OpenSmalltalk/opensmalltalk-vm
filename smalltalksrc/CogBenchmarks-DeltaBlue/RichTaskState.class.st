"
Abstract task that manipulates work packets.
"
Class {
	#name : #RichTaskState,
	#superclass : #RichObject,
	#instVars : [
		'packetPendingIV',
		'taskHolding',
		'taskWaiting'
	],
	#category : #'CogBenchmarks-Richards'
}

{ #category : #'instance creation' }
RichTaskState class >> packetPending [
    ^super new packetPending
]

{ #category : #'instance creation' }
RichTaskState class >> running [
    ^super new running
]

{ #category : #'instance creation' }
RichTaskState class >> waiting [
    ^super new waiting
]

{ #category : #'instance creation' }
RichTaskState class >> waitingWithPacket [
    ^super new waitingWithPacket
]

{ #category : #testing }
RichTaskState >> isPacketPending [
    ^packetPendingIV
]

{ #category : #testing }
RichTaskState >> isRunning [
    ^packetPendingIV not and: [taskWaiting not and: [taskHolding not]]
]

{ #category : #testing }
RichTaskState >> isTaskHolding [
    ^taskHolding
]

{ #category : #testing }
RichTaskState >> isTaskHoldingOrWaiting [
    ^taskHolding or: [packetPendingIV not and: [taskWaiting]]
]

{ #category : #testing }
RichTaskState >> isTaskWaiting [
    ^taskWaiting
]

{ #category : #testing }
RichTaskState >> isWaiting [
    ^packetPendingIV not and: [taskWaiting and: [taskHolding not]]
]

{ #category : #testing }
RichTaskState >> isWaitingWithPacket [
    ^packetPendingIV and: [taskWaiting and: [taskHolding not]]
]

{ #category : #initialize }
RichTaskState >> packetPending [
    packetPendingIV := true.
    taskWaiting := false.
    taskHolding := false
]

{ #category : #initialize }
RichTaskState >> running [
    packetPendingIV := taskWaiting := taskHolding := false
]

{ #category : #accessing }
RichTaskState >> taskHolding: anObject [
	^ taskHolding := anObject
]

{ #category : #accessing }
RichTaskState >> taskWaiting: anObject [
	^ taskWaiting := anObject
]

{ #category : #initialize }
RichTaskState >> waiting [
    packetPendingIV := taskHolding := false.
    taskWaiting := true
]

{ #category : #initialize }
RichTaskState >> waitingWithPacket [
    taskHolding := false.
    taskWaiting := packetPendingIV := true
]
