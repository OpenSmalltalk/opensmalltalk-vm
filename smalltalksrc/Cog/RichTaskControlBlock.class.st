"
A task control block manages a task and the queue of work packages associated with it.
"
Class {
	#name : #RichTaskControlBlock,
	#superclass : #RichTaskState,
	#instVars : [
		'link',
		'identity',
		'priority',
		'input',
		'state',
		'function',
		'handle'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #'instance creation' }
RichTaskControlBlock class >> link: link create: identity priority: priority initialWorkQueue: initialWorkQueue initialState: initialState function: aBlock privateData: privateData [ 
    ^ self new
		link: link
		identity: identity
		priority: priority
		initialWorkQueue: initialWorkQueue
		initialState: initialState
		function: aBlock
		privateData: privateData
]

{ #category : #scheduling }
RichTaskControlBlock >> addInput: packet checkPriority: oldTask [
    input 
	ifNil: 
	    [input := packet.
	    packetPendingIV := true.
	    priority > oldTask priority ifTrue: [ ^ self ]]
	ifNotNil: 
	    [ input := self append: packet head: input ].
    ^ oldTask
]

{ #category : #accessing }
RichTaskControlBlock >> identity [
	^ identity
]

{ #category : #accessing }
RichTaskControlBlock >> link [
	^ link
]

{ #category : #initialize }
RichTaskControlBlock >> link: aLink identity: anIdentity priority: aPriority initialWorkQueue: anInitialWorkQueue initialState: anInitialState function: aBlock privateData: aPrivateData [ 
    link := aLink.
    identity := anIdentity.
    priority := aPriority.
    input := anInitialWorkQueue.
    packetPendingIV := anInitialState isPacketPending.
    taskWaiting := anInitialState isTaskWaiting.
    taskHolding := anInitialState isTaskHolding.
    function := aBlock.
    handle := aPrivateData
]

{ #category : #accessing }
RichTaskControlBlock >> priority [
	^ priority
]

{ #category : #scheduling }
RichTaskControlBlock >> runTask [
    | message |
    self isWaitingWithPacket
	ifTrue: 
	    [message := input.
	    input := message link.
	    input 
		ifNil: [self running]
		ifNotNil: [self packetPending]]
	ifFalse: [message := nil].
    ^ function value: message value: handle
]
