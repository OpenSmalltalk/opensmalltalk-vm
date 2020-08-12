Class {
	#name : #VMMTTests,
	#superclass : #TestCase,
	#instVars : [
		'vm'
	],
	#pools : [
		'VMBasicConstants',
		'VMThreadingConstants'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #running }
VMMTTests >> runCaseManaged [

	^ super runCase
]

{ #category : #running }
VMMTTests >> setUp [
	
	| initialContext |
	super setUp.
	vm := StackMTInterpreterSimulatorForTest
		newWithOptions: #(
			COGMTVM true
			ObjectMemory SpurMockMemory
			FailImbalancedPrimitives false
			MULTIPLEBYTECODESETS true
			bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid).
	vm processHasThreadId: true.
	vm noThreadingOfGUIThread: false.
	vm activeProcessAffined: false.
	vm preemptionYields: true.
	vm foreignCallbackProcessSlot: 56.
	vm stackPointer: -8000.

	vm numStackPages: 8.
	vm stackPages: vm stackPagesClass new.
	vm initStackPages.
	initialContext := VMMockContext new.
	initialContext objectMemory: vm objectMemory.
	vm marryContextInNewStackPageAndInitializeInterpreterRegisters: (vm objectMemory addressOf: initialContext).
	vm newMethod: (vm objectMemory addressOf: initialContext method).

	vm threadManager startThreadSubsystem.
]

{ #category : #willing }
VMMTTests >> testAssignableThreadIsNotVMOwner [

	self assert: vm threadManager currentVMThread state equals: CTMAssignableOrInVM.
	self assert: vm threadManager willingVMThread isNil
]

{ #category : #willing }
VMMTTests >> testAssignableThreadIsWilling [

	| secondThread |
	secondThread := vm threadManager threads second.
	secondThread state: CTMAssignableOrInVM.
	self assert: vm threadManager willingVMThread equals: secondThread.
]

{ #category : #relinquishing }
VMMTTests >> testDisownOnRelinquishPutsVMInRelinquishingState [

	| vmThread process |
	vmThread := vm threadManager vmThreadAt: 1.
	process := vm activeProcess.

	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForProcessorRelinquish fromVMThread: vmThread.
	vm preemptDisowningThread.

	self assert: (vm objectMemory objectFor: process) myList equals: #ProcessInExternalCodeTag
]

{ #category : #disowning }
VMMTTests >> testDisownRemembersLastDisownedThread [

	| previousOwner flagsthread1 |
	previousOwner := vm threadManager currentVMThread.

	"Running from thread 1, we disown to let thread 2"
	flagsthread1 := vm disownVM: DisownVMForFFICall fromVMThread: previousOwner.

	self assert: vm disowningVMThread equals: previousOwner
]

{ #category : #disowning }
VMMTTests >> testDisownVMReleasesVM [

	vm disownVM: DisownVMForFFICall.
	
	"is unowned"
	self assert: vm threadManager getVMOwner equals: 0
]

{ #category : #disowning }
VMMTTests >> testDisownVMSetsCurrentThreadToUnavailable [
	
	| vmThread |
	vmThread := vm threadManager currentVMThread.
	vm disownVM: DisownVMForFFICall.
	
	self assert: vmThread state equals: CTMUnavailable
]

{ #category : #heartbeat }
VMMTTests >> testHeartbeatReleasesVMWhenNoProcessIsWilling [

	| flagsthread1 flagsthread2 c |
	"Running from thread 1, we disown to let thread 2"
	flagsthread1 := vm disownVM: DisownVMForFFICall fromVMThread: (vm threadManager vmThreadAt: 1).
	"Preempt thread 1 and disown thread 2 to let thread 1 take the vm back"
	vm objectMemory processorSchedulerMock
		addProcess: (VMMockProcess new
			objectMemory: vm objectMemory;
			suspendedContext: (VMMockContext new
				objectMemory: vm objectMemory;
				yourself))
		atPriority: 4.
	vm preemptDisowningThread.
	vm activateProcess: vm wakeHighestPriority.
	
	flagsthread2 := vm disownVM: DisownVMForFFICall fromVMThread: (vm threadManager vmThreadAt: 2).
	
	"Own from thread 1, preempting thread 2"
	vm ownVM: flagsthread1.
	"Try to own from thread 2, failing because it is owned by thread 1"
	c := CAContinuation reset: [vm ownVM: flagsthread2].

	"Disown again from thread 1 the VM free, thread 1 busy and thread 2 waiting for ownership"
	flagsthread1 := vm disownVM: DisownVMForFFICall fromVMThread: (vm threadManager vmThreadAt: 1).
	vm checkVMOwnershipFromHeartbeat.

	self assert: vm threadManager getVMOwner equals: 2
]

{ #category : #heartbeat }
VMMTTests >> testHeartbeatWakesUpWaitingVMThread [

	| vmThread |
	vmThread := vm threadManager vmThreadAt: 1.
	
	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForFFICall fromVMThread: vmThread.
	vm checkVMOwnershipFromHeartbeat.

	self assert: vm threadManager getVMOwner equals: 0
]

{ #category : #'initial-state' }
VMMTTests >> testInitialThreadIsAssignableOrInVM [
	
	self assert: vm threadManager currentVMThread state equals: CTMAssignableOrInVM
]

{ #category : #'initial-state' }
VMMTTests >> testInitialVMHasManyThreads [
	
	self assert: vm threadManager threads size equals: 6
]

{ #category : #'initial-state' }
VMMTTests >> testInitialVMHasNoDisowningVMThread [
	
	self assert: vm disowningVMThread isNil
]

{ #category : #'initial-state' }
VMMTTests >> testInitialVMThreadsAreUinitialized [
	
	self assert: (vm threadManager threads allButFirst allSatisfy: [ :e | e state = nil ]).
]

{ #category : #disowning }
VMMTTests >> testOwnFreeVMOwnsSameThread [

	| previousOwner flags |
	previousOwner := vm threadManager currentVMThread.
	flags := vm disownVM: DisownVMForFFICall.
	vm ownVM: flags.
	
	self assert: vm threadManager currentVMThread equals: previousOwner
]

{ #category : #preemption }
VMMTTests >> testPreemptedProcessIsMarkedInExternalCode [

	| vmThread process |
	vmThread := vm threadManager vmThreadAt: 1.
	process := vm activeProcess.
	
	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForFFICall fromVMThread: vmThread.
	vm preemptDisowningThread.

	self assert: (vm objectMemory objectFor: process) myList equals: #ProcessInExternalCodeTag
]

{ #category : #preemption }
VMMTTests >> testPreemptedProcessSetsCurrentMethodInThread [

	| vmThread process |
	vmThread := vm threadManager vmThreadAt: 1.
	process := vm activeProcess.
	
	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForFFICall fromVMThread: vmThread.
	vm preemptDisowningThread.

	self assert: (vm objectMemory objectFor: vmThread newMethodOrNull) equals: (vm objectMemory objectFor: process) suspendedContext method
]

{ #category : #preemption }
VMMTTests >> testPreemptedVMThreadHasPreemptedProcessPriority [

	| vmThread process |
	vmThread := vm threadManager vmThreadAt: 1.
	process := vm objectMemory objectFor: vm activeProcess.
	process priority: 1.
	
	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForFFICall fromVMThread: vmThread.
	vm preemptDisowningThread.

	self assert: vmThread priority equals: 1
]

{ #category : #preemption }
VMMTTests >> testPreemptedVMThreadIsListedInAWOLProcesses [

	| vmThread process |
	vmThread := vm threadManager vmThreadAt: 1.
	process := vm activeProcess.
	
	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForFFICall fromVMThread: vmThread.
	vm preemptDisowningThread.

	self assert: (vmThread awolProcesses includes: process)
]

{ #category : #preemption }
VMMTTests >> testPreemptedVMThreadIsTemporarilyAffinedToProcess [

	| vmThread process |
	vmThread := vm threadManager vmThreadAt: 1.
	process := vm objectMemory objectFor: vm activeProcess.
	process priority: 1.
	
	"Running from thread 1, we disown to let thread 2"
	vm disownVM: DisownVMForFFICall fromVMThread: vmThread.
	vm preemptDisowningThread.

	self assert: process threadIndex equals: vmThread index.
	self assert: process isTemporarilyAffined
]

{ #category : #heartbeat }
VMMTTests >> testTryOwningOwnedVMLeavesThreadInWaitingState [

	| flagsthread1 flagsthread2 c |
	"Running from thread 1, we disown to let thread 2"
	flagsthread1 := vm disownVM: DisownVMForFFICall fromVMThread: (vm threadManager vmThreadAt: 1).
	"Preempt thread 1 and disown thread 2 to let thread 1 take the vm back"
	vm objectMemory processorSchedulerMock
		addProcess: (VMMockProcess new
			objectMemory: vm objectMemory;
			suspendedContext: (VMMockContext new
				objectMemory: vm objectMemory;
				yourself))
		atPriority: 4.
	vm preemptDisowningThread.
	vm activateProcess: vm wakeHighestPriority.
	
	flagsthread2 := vm disownVM: DisownVMForFFICall fromVMThread: (vm threadManager vmThreadAt: 2).
	
	"Own from thread 1, preempting thread 2"
	vm ownVM: flagsthread1.
	"Try to own from thread 2, failing because it is owned by thread 1"
	c := CAContinuation reset: [vm ownVM: flagsthread2].
	
	self assert: (vm threadManager vmThreadAt: 2) state equals: CTMWantingOwnership
]

{ #category : #willing }
VMMTTests >> testWantingThreadIsWilling [

	| secondThread |
	secondThread := vm threadManager threads second.
	secondThread state: CTMWantingOwnership.
	self assert: vm threadManager willingVMThread equals: secondThread.
]

{ #category : #willing }
VMMTTests >> testWantingThreadIsWillingOverAssignableThread [

	| wantingThread willingThread |
	wantingThread := vm threadManager threads second.
	willingThread := vm threadManager threads third.
	wantingThread state: CTMWantingOwnership.
	willingThread state: CTMAssignableOrInVM.
	self assert: vm threadManager willingVMThread equals: wantingThread.
]
