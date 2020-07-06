Class {
	#name : #VMFFIHelpersTest,
	#superclass : #VMAbstractFFITest,
	#category : #VMMakerTests
}

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> assertPopInEmptyStackFails [

	[ interpreter popSameThreadCalloutSuspendedProcess.
	self fail ]
		onErrorDo: [ :anError | 
			self
				assert: anError messageText
				equals: 'SameThreadCalloutSuspendedProcessStack is empty' ]
]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPopSameThreadCalloutSuspendedProcessInEmptyStackRaisesError [

 	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	
	
	self assertPopInEmptyStackFails
]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushPushThenPopPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsFirstPushedProcess [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	interpreter popSameThreadCalloutSuspendedProcess.
	
	self assert: interpreter popSameThreadCalloutSuspendedProcess equals: aProcess.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushPushThenPopPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsFirstPushedProcessWithNilNextLink [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	interpreter popSameThreadCalloutSuspendedProcess.
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: interpreter popSameThreadCalloutSuspendedProcess) equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsLastPushedProcess [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	self assert: interpreter popSameThreadCalloutSuspendedProcess equals: anotherProcess.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsLastPushedProcessWithNilNextLink [

 	| aProcess anotherProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	anotherProcess := self createSuspendedProcessFor: memory nilObject priority: 1.

	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	interpreter pushSameThreadCalloutSuspendedProcess: anotherProcess.
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: interpreter popSameThreadCalloutSuspendedProcess) equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushSameThreadCalloutSuspendedProcessInEmptyStackStoresThePassedProcess [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createProcessFor: memory nilObject priority: 2.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: (memory splObj: SuspendedProcessInCallout) equals: aProcess.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushSameThreadCalloutSuspendedProcessInEmptyStackUpdatesNextLinkWithNil [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: aProcess) equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushThenPopPopSameThreadCalloutSuspendedProcessInEmptyStackFails [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 

	interpreter popSameThreadCalloutSuspendedProcess.
	
	self assertPopInEmptyStackFails	

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsProcessWithNilInNextLink [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: (memory fetchPointer: NextLinkIndex ofObject: aProcess)  equals: memory nilObject.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testPushThenPopSameThreadCalloutSuspendedProcessInEmptyStackReturnsPushedProcess [

 	| aProcess |
	self assert: (memory splObj: SuspendedProcessInCallout) equals: memory nilObject.	

	aProcess := self createSuspendedProcessFor: memory nilObject priority: 1.
	interpreter pushSameThreadCalloutSuspendedProcess: aProcess. 
	
	self assert: interpreter popSameThreadCalloutSuspendedProcess equals: aProcess.

]

{ #category : #'tests - helpers' }
VMFFIHelpersTest >> testReadAddressReadsTheValidAddressValue [

	| anExternalAddress |
	anExternalAddress := self newExternalAddress: 4.
	self assert: (interpreter readAddress: anExternalAddress) equals: 4
]
