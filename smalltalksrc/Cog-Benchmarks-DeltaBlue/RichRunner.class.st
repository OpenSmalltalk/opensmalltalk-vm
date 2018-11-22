"
Richards simulates the task dispatcher of an operating system.
"
Class {
	#name : #RichRunner,
	#superclass : #RichObject,
	#instVars : [
		'taskList',
		'currentTask',
		'currentTaskIdentity',
		'taskTable',
		'queuePacketCount',
		'holdCount'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #starting }
RichRunner class >> start [
    "RichardsBenchmark start"

    ^self new start
]

{ #category : #creation }
RichRunner >> createDevice: identity priority: priority work: work state: state [ 
    | data |
    data := RichDeviceTaskDataRecord new.
    self
	createTask: identity
	priority: priority
	work: work
	state: state
	function: 
	    [:work1 :word | | data1 functionWork |
	    data1 := word.
	    functionWork := work1.
	    functionWork 
		ifNil:
		    [(functionWork := data1 pending) isNil
			ifTrue: [self wait]
			ifFalse: 
			    [data1 pending: nil.
			    self queuePacket: functionWork]]
		ifNotNil: 
		    [data1 pending: functionWork.
		    self holdSelf]]
	data: data
]

{ #category : #creation }
RichRunner >> createHandler: identity priority: priority work: work state: state [ 
    | data |
    data := RichHandlerTaskDataRecord new.
    self
	createTask: identity
	priority: priority
	work: work
	state: state
	function: 
	    [:work1 :word | | data1 workPacket count devicePacket |
	    data1 := word.
	    work1 
		ifNotNil: [WorkPacketKind == work1 kind 
		    ifTrue: [data1 workInAdd: work1]
		    ifFalse: [data1 deviceInAdd: work1]].
	    (workPacket := data1 workIn) 
		ifNil: [self wait]
		ifNotNil: 
		    [count := workPacket datum.
		    count > 4
			ifTrue: 
			    [data1 workIn: workPacket link.
			    self queuePacket: workPacket]
			ifFalse:
			    [(devicePacket := data1 deviceIn) 
				ifNil: [self wait]
				ifNotNil: 
				    [data1 deviceIn: devicePacket link.
				    devicePacket datum: (workPacket data at: count).
				    workPacket datum: count + 1.
				    self queuePacket: devicePacket]]]]
	data: data
]

{ #category : #creation }
RichRunner >> createIdler: identity priority: priority work: work state: state [ 
    | data |
    data := RichIdleTaskDataRecord new.
    self
	createTask: identity
	priority: priority
	work: work
	state: state
	function: 
	    [:work1 :word | | data1 |
	    data1 := word.
	    data1 count: data1 count - 1.
	    0 = data1 count
		ifTrue: [self holdSelf]
		ifFalse:
		    [0 = (data1 control bitAnd: 1)
			ifTrue: 
			    [data1 control: data1 control // 2.
			    self release: DeviceA]
			ifFalse: 
			    [data1 control: (data1 control // 2 bitXor: 53256).
			    self release: DeviceB]]]
	data: data
]

{ #category : #creation }
RichRunner >> createPacket: link identity: identity kind: kind [ 
    ^ RichPacket
		create: link
		identity: identity
		kind: kind
]

{ #category : #creation }
RichRunner >> createTask: identity priority: priority work: work state: state function: aBlock data: data [ 
    | t |
    t := RichTaskControlBlock
		link: taskList
		create: identity
		priority: priority
		initialWorkQueue: work
		initialState: state
		function: aBlock
		privateData: data.
    taskList := t.
    taskTable at: identity put: t
]

{ #category : #creation }
RichRunner >> createWorker: identity priority: priority work: work state: state [ 
    | data |
    data := RichWorkerTaskDataRecord new.
    self
	createTask: identity
	priority: priority
	work: work
	state: state
	function: 
	    [:work1 :word | | data1 |
	    data1 := word.
	    work1
		ifNil: [self wait]
		ifNotNil: 
		    [data1 destination: (HandlerA = data1 destination
			    ifTrue: [HandlerB]
			    ifFalse: [HandlerA]).
		    work1 identity: data1 destination.
		    work1 datum: 1.
		    1 to: 4 do: [ :i | 
			data1 count: data1 count + 1.
			data1 count > 26 ifTrue: [data1 count: 1].
			work1 data at: i put: $A asInteger + data1 count - 1].
		    self queuePacket: work1]]
	data: data
]

{ #category : #private }
RichRunner >> findTask: identity [ 
    | t |
    t := taskTable at: identity.
    t ifNil: [self error: 'findTask failed'].
    ^ t
]

{ #category : #private }
RichRunner >> holdSelf [
    holdCount := holdCount + 1.
    currentTask taskHolding: true.
    ^ currentTask link
]

{ #category : #private }
RichRunner >> initScheduler [
    queuePacketCount := holdCount := 0.
    taskTable := Array new: 6.
    taskList := nil
]

{ #category : #private }
RichRunner >> queuePacket: packet [ 
    | t |
    t := self findTask: packet identity.
    t ifNil: [ ^ nil ].
    queuePacketCount := queuePacketCount + 1.
    packet link: nil.
    packet identity: currentTaskIdentity.
    ^ t addInput: packet checkPriority: currentTask
]

{ #category : #private }
RichRunner >> release: identity [ 
    | t |
    t := self findTask: identity.
    t ifNil: [ ^ nil ].
    t taskHolding: false.
    ^ t priority > currentTask priority
	ifTrue: [ t ]
	ifFalse: [ currentTask ]
]

{ #category : #scheduling }
RichRunner >> schedule [
    currentTask := taskList. 
    [currentTask isNil]
	whileFalse: 
	    [currentTask isTaskHoldingOrWaiting
		ifTrue: [currentTask := currentTask link]
		ifFalse: 
		    [currentTaskIdentity := currentTask identity.
		    currentTask := currentTask runTask]]
]

{ #category : #initialize }
RichRunner >> start [
    | workQ |
    self initScheduler.
    self
	createIdler: Idler
	priority: 0
	work: nil
	state: RichTaskState running.
    workQ := self
		createPacket: nil
		identity: Worker
		kind: WorkPacketKind.
    workQ := self
		createPacket: workQ
		identity: Worker
		kind: WorkPacketKind.
    self
	createWorker: Worker
	priority: 1000
	work: workQ
	state: RichTaskState waitingWithPacket.
    workQ := self
		createPacket: nil
		identity: DeviceA
		kind: DevicePacketKind.
    workQ := self
		createPacket: workQ
		identity: DeviceA
		kind: DevicePacketKind.
    workQ := self
		createPacket: workQ
		identity: DeviceA
		kind: DevicePacketKind.
    self
	createHandler: HandlerA
	priority: 2000
	work: workQ
	state: RichTaskState waitingWithPacket.
    workQ := self
		createPacket: nil
		identity: DeviceB
		kind: DevicePacketKind.
    workQ := self
		createPacket: workQ
		identity: DeviceB
		kind: DevicePacketKind.
    workQ := self
		createPacket: workQ
		identity: DeviceB
		kind: DevicePacketKind.
    self
	createHandler: HandlerB
	priority: 3000
	work: workQ
	state: RichTaskState waitingWithPacket.
    self
	createDevice: DeviceA
	priority: 4000
	work: nil
	state: RichTaskState waiting.
    self
	createDevice: DeviceB
	priority: 5000
	work: nil
	state: RichTaskState waiting.
    self schedule.
    queuePacketCount = 23246 & (holdCount = 9297) ifFalse: [self error: 'wrong result'].

]

{ #category : #private }
RichRunner >> wait [ 
    currentTask taskWaiting: true.
    ^ currentTask
]
