Class {
	#name : #CoInterpreterMT,
	#superclass : #CoInterpreterPrimitives,
	#instVars : [
		'cogThreadManager',
		'checkThreadActivation',
		'maxWaitingPriority',
		'foreignCallbackPriority',
		'deferThreadSwitch',
		'disowningVMThread',
		'disownCount',
		'foreignCallbackProcessSlot',
		'willNotThreadWarnCount',
		'activeProcessAffined',
		'relinquishing',
		'processHasThreadId',
		'noThreadingOfGUIThread'
	],
	#classVars : [
		'DisownFlagsShift',
		'DisownVMForProcessorRelinquish',
		'LockGUIThreadFlag',
		'LockGUIThreadShift',
		'OwnVMForeignThreadFlag',
		'ProcessUnaffinedOnDisown',
		'ReturnToThreadSchedulingLoop',
		'VMAlreadyOwnedHenceDoNotDisown'
	],
	#pools : [
		'VMThreadingConstants'
	],
	#category : #'VMMaker-Multithreading'
}

{ #category : #translation }
CoInterpreterMT class >> ancilliaryClasses: options [
	^(super ancilliaryClasses: options), { CogThreadManager. CogVMThread }
]

{ #category : #translation }
CoInterpreterMT class >> apiExportHeaderName [
	^'cointerpmt.h'
]

{ #category : #translation }
CoInterpreterMT class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		addHeaderFile:'"sqAtomicOps.h"'. "For THRLOG"
	aCCodeGenerator vmClass
		declareInterpreterVersionIn: aCCodeGenerator
		defaultName: 'Cog MT'.
	aCCodeGenerator
		var: #disowningVMThread type: #'CogVMThread *'
]

{ #category : #initialization }
CoInterpreterMT class >> initializeMiscConstants [

	super initializeMiscConstants.

	"N.B. some of these DisownFlags are replicated in platforms/Cross/vm/sqVirtualMachine.h.
	 Hence they should always be initialized."
	DisownVMLockOutFullGC := 1.
	DisownVMForProcessorRelinquish := 2.

	(initializationOptions notNil
	 and: [(initializationOptions at: #COGMTVM ifAbsent: [false]) == false]) ifTrue:
		[^self].

	COGMTVM := true.

	ReturnToThreadSchedulingLoop := 2. "setjmp/longjmp code."
]

{ #category : #initialization }
CoInterpreterMT class >> initializePrimitiveTable [
	super initializePrimitiveTable.
	COGMTVM ifTrue:
		[(227 to: 229) do:
			[:pidx| self assert: (PrimitiveTable at: pidx + 1) = #primitiveFail].
		PrimitiveTable
			at: 227 + 1 put: #primitiveVMCurrentThreadId;
			at: 228 + 1 put: #primitiveProcessBoundThreadId;
			at: 229 + 1 put: #primitiveProcessBindToThreadId]
]

{ #category : #initialization }
CoInterpreterMT class >> initializeSchedulerIndices [
	super initializeSchedulerIndices.
	"Class Process"
	ThreadIdIndex := 4.

	"disown result/own argument flags & max number of threads"
	LockGUIThreadShift := 16.
	LockGUIThreadFlag := 1 << LockGUIThreadShift.
	OwnVMForeignThreadFlag := 1 << (LockGUIThreadShift + 1).
	VMAlreadyOwnedHenceDoNotDisown := 1 << (LockGUIThreadShift + 2).
	ProcessUnaffinedOnDisown := 1 << (LockGUIThreadShift + 3).
	DisownFlagsShift := LockGUIThreadShift + 4.
	ThreadIdMask := (1 << LockGUIThreadShift) - 1 "results in 64k thread indices"

]

{ #category : #accessing }
CoInterpreterMT class >> interpreterVersion [ 
	^ 'Cog MT'
]

{ #category : #translation }
CoInterpreterMT class >> isNonArgumentImplicitReceiverVariableName: aString [
	^'cogThreadManager' = aString
	   or: [super isNonArgumentImplicitReceiverVariableName: aString]
]

{ #category : #testing }
CoInterpreterMT class >> isThreadedVM [
	^true
]

{ #category : #translation }
CoInterpreterMT class >> mustBeGlobal: var [
	"Make disownCount global so that debugging/instrumentation code can use it to check
	 if a threaded FFI call is in progress (i.e. this isn't necessary for production)"

	^(super mustBeGlobal: var)
	   or: [ #('disownCount' 'willNotThreadWarnCount') includes: var]
]

{ #category : #'accessing class hierarchy' }
CoInterpreterMT class >> primitivesClass [
	^CoInterpreterMT
]

{ #category : #translation }
CoInterpreterMT class >> sourceFileName [
	"Answer the filename for the core interpreter"

	^'cointerpmt.c'
]

{ #category : #simulation }
CoInterpreterMT >> assertCStackPointersBelongToCurrentThread [
	<doNotGenerate>
	| range |
	range := self cStackRangeForCurrentThread.
	self assert: ((range includes: cogit getCStackPointer)
				and: [range includes: cogit getCFramePointer])
]

{ #category : #simulation }
CoInterpreterMT >> assertCStackPointersBelongToCurrentVMOwner [
	<doNotGenerate>
	| range |
	range := self cStackRangeForCurrentVMOwner.
	self assert: (range notNil "VM is owned"
				and: [(range includes: cogit getCStackPointer)
				and: [range includes: cogit getCFramePointer]])
]

{ #category : #'debug support' }
CoInterpreterMT >> assertSaneThreadAndProcess [
	<inline: true>
	self assert: cogThreadManager getVMOwner > 0.
	self assert: cogThreadManager currentVMThread state = CTMAssignableOrInVM.
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject
]

{ #category : #'process primitive support' }
CoInterpreterMT >> bindProcess: aProcess toId: newId [
	"Change a Process's thread binding and answer 0, otherwise answer a suitable error code.
	 Cases:
		process is unbound & unaffined
			id 0 nothing to do
			id non-zero ensure thread and bind
		process is affined (temporarily bound to a thread for the duration of a surrender of ownership)
			id = affined index nothing to do
			id = 0 nothing to do
			id ~= 0 && id ~= affined index fail
		process is bound (permanently bound to a thread)
			id = bound index nothing to do
			id ~= bound index set bound index"
	| threadId ownerIndex newThreadIndex |
	processHasThreadId ifFalse:
		[^PrimErrUnsupported].

	threadId := self threadIdFieldOf: aProcess.
	newThreadIndex := self ownerIndexOfThreadId: newId.
	ownerIndex := self ownerIndexOfThreadId: threadId.

	(self isAffinedThreadId: threadId) ifTrue:
		[(ownerIndex = newId
		  or: [newId = 0]) ifTrue:
			[^0].
		^PrimErrInappropriate].

	newThreadIndex > 0 ifTrue:
		[(self startThreadForThreadIndex: newThreadIndex) ifFalse:
			[^PrimErrLimitExceeded]].

	self setOwnerIndexOfProcess: aProcess to: newId bind: true.
	^0
]

{ #category : #simulation }
CoInterpreterMT >> cStackRangeForCurrentThread [
	<doNotGenerate>
	^self cStackRangeForThreadIndex: cogThreadManager ioGetThreadLocalThreadIndex
]

{ #category : #simulation }
CoInterpreterMT >> cStackRangeForCurrentVMOwner [
	<doNotGenerate>
	^self cStackRangeForThreadIndex: cogThreadManager getVMOwner
]

{ #category : #simulation }
CoInterpreterMT >> cStackRangeForThreadIndex: threadIndex [
	"Each simulated processor thread gets 4k of the rump C stack.
	 The top-most section is reserved for in-memory variables such as vmOwnerLock."
	<doNotGenerate>
	| top |
	^(threadIndex between: 1 and: cogThreadManager maxNumThreads) ifTrue:
		[top := self rumpCStackAddress - (threadIndex * RumpCStackSize).
		 top - RumpCStackSize + 1 to: top]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> cedeToHigherPriorityThreads [
	"Invoked from checkForEventsMayContextSwitch: to switch threads if a thread
	 wanting to acquire the VM has higher priority than the active process."
	| activeProc ownerIndex activeContext activePriority activeThread vmThread |
	<var: #activeThread type: #'CogVMThread *'>
	<var: #vmThread type: #'CogVMThread *'>
	<inline: false>
	activeProc := self activeProcess.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	ownerIndex := self ownerIndexOfProcess: activeProc.
	ownerIndex = 0
		ifTrue: [activeThread := cogThreadManager currentVMThread]
		ifFalse: [activeThread := cogThreadManager vmThreadAt: ownerIndex].
	activeThread priority: activePriority.
	vmThread := cogThreadManager
					highestPriorityThreadIfHigherThan: activePriority
					expectedMax: maxWaitingPriority.
	(vmThread isNil					"no waiting thread of sufficiently high priority.  Do not switch."
	or: [vmThread = activeThread]) "The activeProcess needs to run on a different thread.  Leave this to
									  threadSwitchIfNecessary:from: in checkForEventsMayContextSwitch:"
		ifTrue:
			[maxWaitingPriority > activePriority ifTrue:
				[maxWaitingPriority := activePriority].
			 ^self].

	self assert: vmThread priority > activePriority.
	self assert: vmThread ~= cogThreadManager currentVMThread.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.

	maxWaitingPriority > vmThread priority ifTrue:
		[maxWaitingPriority := vmThread priority].
	statProcessSwitch := statProcessSwitch + 1.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	objectMemory storePointer: SuspendedContextIndex ofObject: activeProc withValue: activeContext.
	self ensurePushedInstructionPointer.
	self externalWriteBackHeadFramePointers.
	self putToSleep: activeProc yieldingIf: preemptionYields.
	"Transcript cr; print: #cedeToHighestPriorityThreadIfHigherThan:; cr.
	  self printExternalHeadFrame.
	  self print: 'ip: '; printHex: self instructionPointer. Transcript cr; flush."
	self returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: CSCheckEvents
]

{ #category : #'process primitive support' }
CoInterpreterMT >> checkForEventsMayContextSwitch: mayContextSwitch [
	"Check for possible interrupts and handle one if necessary.
	 Answer if a context switch has occurred."
	| switched sema now |
	<inline: false>
	<var: #now type: #usqLong>
	self assertSaneThreadAndProcess.
	cogit assertCStackWellAligned.
	statCheckForEvents := statCheckForEvents + 1.

	"restore the stackLimit if it has been smashed."
	self restoreStackLimit.
	self externalWriteBackHeadFramePointers.
	self assert: stackPage = stackPages mostRecentlyUsedPage.

	"Allow the platform to do anything it needs to do synchronously."
	self ioSynchronousCheckForEvents.

	self checkCogCompiledCodeCompactionCalledFor.

	objectMemory needGCFlag ifTrue:
		["sufficientSpaceAfterGC: runs the incremental GC and
		 then, if not enough space is available, the fullGC."
		 (objectMemory sufficientSpaceAfterGC: 0) ifFalse:
			[self setSignalLowSpaceFlagAndSaveProcess]].

	mayContextSwitch ifFalse: [^false].

	switched := false.
	self assert: deferThreadSwitch not.
	deferThreadSwitch := true.

	(profileProcess ~= objectMemory nilObject
	 or: [nextProfileTick > 0 and:[self ioHighResClock >= nextProfileTick]]) ifTrue:
		[nextProfileTick := 0.
		 "Take a sample (if not already done so) for the profiler if it is active.  This
		  must be done before any of the synchronousSignals below or else we will
		  attribute a pause in ioRelinquishProcessor to the newly activated process."
		 profileProcess = objectMemory nilObject ifTrue:
			[profileProcess := self activeProcess.
			 profileMethod := objectMemory nilObject].
		 "and signal the profiler semaphore if it is present"
		 (profileSemaphore ~= objectMemory nilObject
		  and: [self synchronousSignal: profileSemaphore]) ifTrue:
			[switched := true]].

	self checkDeliveryOfLongRunningPrimitiveSignal ifTrue:
		[switched := true].

	objectMemory signalLowSpace ifTrue:
		[objectMemory signalLowSpace: false. "reset flag"
		 sema := objectMemory splObj: TheLowSpaceSemaphore.
		 (sema ~= objectMemory nilObject
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	"inIOProcessEvents prevents reentrancy into ioProcessEvents and allows disabling
	 ioProcessEvents e.g. for native GUIs.  We would like to manage that here but can't
	 since the platform code may choose to call ioProcessEvents itself in various places."
	false
		ifTrue:
			[((now := self ioUTCMicroseconds) >= nextPollUsecs
			 and: [inIOProcessEvents = 0]) ifTrue:
				[statIOProcessEvents := statIOProcessEvents + 1.
				 inIOProcessEvents := inIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 inIOProcessEvents > 0 ifTrue:
					[inIOProcessEvents := inIOProcessEvents - 1].
				 nextPollUsecs := now + 20000
				 "msecs to wait before next call to ioProcessEvents.  Note that strictly
				  speaking we might need to update 'now' at this point since
				  ioProcessEvents could take a very long time on some platforms"]]
		ifFalse:
			[(now := self ioUTCMicroseconds) >= nextPollUsecs ifTrue:
				[statIOProcessEvents := statIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 nextPollUsecs := now + 20000
				 "msecs to wait before next call to ioProcessEvents.  Note that strictly
				  speaking we might need to update 'now' at this point since
				  ioProcessEvents could take a very long time on some platforms"]].

	interruptPending ifTrue:
		[interruptPending := false.
		 "reset interrupt flag"
		 sema := objectMemory splObj: TheInterruptSemaphore.
		 (sema ~= objectMemory nilObject
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	nextWakeupUsecs ~= 0 ifTrue:
		[now >= nextWakeupUsecs ifTrue:
			[nextWakeupUsecs := 0.
			 "set timer interrupt to 0 for 'no timer'"
			 sema := objectMemory splObj: TheTimerSemaphore.
			 (sema ~= objectMemory nilObject
			  and: [self synchronousSignal: sema]) ifTrue:
				[switched := true]]].

	"signal any pending finalizations"
	pendingFinalizationSignals > 0 ifTrue:
		[pendingFinalizationSignals := 0.
		 sema := objectMemory splObj: TheFinalizationSemaphore.
		 (sema ~= objectMemory nilObject
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	"signal all semaphores in semaphoresToSignal"
	self signalExternalSemaphores ifTrue:
		[switched := true].

	deferThreadSwitch := false.
	checkThreadActivation ifTrue:
		[checkThreadActivation := false.
		 self cedeToHigherPriorityThreads]. "N.B.  This may not return if we do switch."

	self threadSwitchIfNecessary: self activeProcess from: CSCheckEvents.
	^switched
]

{ #category : #'process primitive support' }
CoInterpreterMT >> checkVMOwnershipFromHeartbeat [
	"Check whether the VM is unowned and needs to set a thread running to try and own it.
	 Do not attempt this if the image doesn't have a threadId inst var in Process; the VM
	 can't thread these images."
	<inline: false>
	self sqLowLevelMFence.
	(processHasThreadId
	 and: [cogThreadManager getVMOwner = 0]) ifTrue:
		[cogThreadManager ensureRunningVMThread: relinquishing]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> deferStackLimitSmashAround: functionSymbol [
	"Defer smashes of the stackLimit around the call of functionSymbol (for assert checks).	

	 N.B. SYNCHRONIZE WITH forceInterruptCheckFromHeartbeat"

	<var: #functionSymbol declareC: 'void (*functionSymbol)(void)'>
	deferSmash := true.
	self perform: functionSymbol.
	deferSmash := false.
	deferredSmash ifTrue:
		[deferredSmash := false.
		 self forceInterruptCheck.
		 self checkVMOwnershipFromHeartbeat].
	^true "called from assert"
]

{ #category : #'process primitive support' }
CoInterpreterMT >> deferStackLimitSmashAround: functionSymbol with: arg [
	"Defer smashes of the stackLimit around the call of functionSymbol (for assert checks).	

	 N.B. SYNCHRONIZE WITH forceInterruptCheckFromHeartbeat"

	<var: #functionSymbol declareC: 'void (*functionSymbol)(sqInt)'>
	deferSmash := true.
	self sqLowLevelMFence.
	self perform: functionSymbol with: arg.
	deferSmash := false.
	self sqLowLevelMFence.
	deferredSmash ifTrue:
		[deferredSmash := false.
		 self sqLowLevelMFence.
		 self forceInterruptCheck.
		 self checkVMOwnershipFromHeartbeat].
	^true "called from assert"
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> disownVM: flags [
	"Release the VM to other threads and answer the current thread's index.
	 Currently valid flags:
		DisownVMLockOutFullGC	- prevent fullGCs while this thread disowns the VM.
		OwnVMForeignThreadFlag	- indicates lowest-level entry from a foreign thread
									- not to be used explicitly by clients
									- only set by ownVMFromUnidentifiedThread
		VMAlreadyOwnedHenceDoNotDisown
									- indicates an ownVM from a callback was made when
									  the vm was still owned.
									- not to be used explicitly by clients
									- only set by ownVMFromUnidentifiedThread

	 This is the entry-point for plugins and primitives that wish to release the VM while
	 performing some operation that may potentially block, and for callbacks returning
	 back to some blocking operation.  If this thread does not reclaim the VM before-
	 hand then when the next heartbeat occurs the thread manager will schedule a
	 thread to acquire the VM which may start running the VM in place of this thread.

	 N.B. Most of the state needed to resume after preemption is set in preemptDisowningThread."
	<api>
	<inline: false>
	| vmThread result |
	<var: #vmThread type: #'CogVMThread *'>
	self assert: self successful.
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceDisownVM thing: (objectMemory integerObjectOf: flags) source: 0].
	processHasThreadId ifFalse:
		[willNotThreadWarnCount < 10 ifTrue:
			[self print: 'warning: VM parameter 48 indicates Process doesn''t have threadId; VM will not thread'; cr.
			 willNotThreadWarnCount := willNotThreadWarnCount + 1]].
	vmThread := cogThreadManager currentVMThread.
	(flags anyMask: VMAlreadyOwnedHenceDoNotDisown) ifTrue:
		[disowningVMThread := vmThread.
		 vmThread state: CTMUnavailable.
		 ^0].
	self cCode: ''
		inSmalltalk:
			[| range |
			 range := self cStackRangeForThreadIndex: vmThread index.
			 self assert: (range includes: cogit getCStackPointer).
			 self assert: (range includes: cogit getCFramePointer)].
	(flags anyMask: DisownVMForProcessorRelinquish) ifTrue:
		[| proc |
		 (proc := objectMemory splObj: foreignCallbackProcessSlot) ~= objectMemory nilObject ifTrue:
			[foreignCallbackPriority := self quickFetchInteger: PriorityIndex ofObject: proc].
		 relinquishing := true.
		 self sqLowLevelMFence].
	(flags anyMask: DisownVMLockOutFullGC) ifTrue:
		[objectMemory incrementFullGCLock].
	(noThreadingOfGUIThread and: [self inGUIThread]) ifTrue:
		[^vmThread index
		 + LockGUIThreadFlag
		 + (activeProcessAffined ifTrue: [0] ifFalse: [ProcessUnaffinedOnDisown])
		 + (flags << DisownFlagsShift)].
	disownCount := disownCount + 1.
	disowningVMThread := vmThread.
	"self cr; cr; print: 'disownVM  Csp: '; printHex: vmThread cStackPointer; cr.
	(0 to: 16 by: 4) do:
		[:offset|
		self print: ' *(esp+'; printNum: offset; print: ': '; printHex: (stackPages longAt: cogit processor sp + offset); cr].
	cogit processor printIntegerRegistersOn: Transcript."

	"OwnVMForeignThreadFlag indicates lowest-level of entry by a foreign
	 thread. If that's where we are then release the vmThread.  Otherwise
	 indicate the vmThread is off doing something outside of the VM."
	(flags anyMask: OwnVMForeignThreadFlag)
		ifTrue:
			["I don't think this is quite right.  Josh's use case is creating some foreign thread and then registering
			 it with the VM. That's not the same as binding a process to a foreign thread given that the foreign
			 callback process is about to terminate anyway (it is returning from a callback here).  So do we need
			 an additional concept, that of a vmThread being either of the set known to the VM or floating?"
			self flag: 'issue with registering foreign threads with the VM'.
			(self isBoundProcess: self activeProcess) ifFalse:
				[cogThreadManager unregisterVMThread: vmThread]]
		ifFalse: [vmThread state: CTMUnavailable].
	result := vmThread index
				+ (activeProcessAffined ifTrue: [0] ifFalse: [ProcessUnaffinedOnDisown])
				+ (flags << DisownFlagsShift).
	cogThreadManager releaseVM.
	^result
]

{ #category : #initialization }
CoInterpreterMT >> enterSmalltalkExecutive [
	"Main entry-point into the interpreter at each execution level, where an
	 execution level is either the start of execution or reentry for a callback."
	<cmacro: '() enterSmalltalkExecutiveImplementation()'>
	"Simulation of the setjmp in enterSmalltalkExecutiveImplementation for reentry
	 into interpreter.  Simulation of the register state switch on thread switch."
	| vmo tlti thisActivationsSP thisActivationsFP retVal |
	[vmo := cogThreadManager getVMOwner.
	 tlti := cogThreadManager ioGetThreadLocalThreadIndex.
	 self assert: vmo = tlti.
	 thisActivationsSP := cogit processor sp.
	 thisActivationsFP := cogit processor fp.
	 retVal := [self enterSmalltalkExecutiveImplementation]
				on: ReenterInterpreter
				do: [:ex|
					vmo := cogThreadManager getVMOwner.
					tlti := cogThreadManager ioGetThreadLocalThreadIndex.
					self assert: (ex returnValue = ReturnToThreadSchedulingLoop
								 or: [vmo = tlti]).
					ex return: ex returnValue].
	 "We must cut back the stack pointers on return to mimic the longjmp."
	 cogit processor
		setFramePointer: thisActivationsFP
		stackPointer: thisActivationsSP.
	 retVal = ReturnToInterpreter] whileTrue
]

{ #category : #'callback support' }
CoInterpreterMT >> enterSmalltalkExecutiveFromCallback [
	<inline: true>
	self threadSchedulingLoop: cogThreadManager currentVMThread
]

{ #category : #initialization }
CoInterpreterMT >> enterSmalltalkExecutiveImplementation [
	"Main entry-point into the interpreter at each execution level, where an execution
	 level is either the start of execution or reentry for a callback.  Capture the C stack
	 pointers so that calls from machine-code into the C run-time occur at this level.
	 This is the actual implementation, separated from enterSmalltalkExecutive so the
	 simulator can wrap it in an exception handler and hence simulate the setjmp/longjmp.

	 Override to return if a longjmp to reenterInterpreter passes a parameter greater than 1.
	 This causes a return to threadSchedulingLoop:startingVM: and is used to surrender
	 control to another thread."
	<inline: false>
	self assertSaneThreadAndProcess.
	cogit assertCStackWellAligned.
	cogit ceCaptureCStackPointers.
	"Setjmp for reentry into interpreter from elsewhere, e.g. machine-code trampolines."
	(self sigset: reenterInterpreter jmp: 0) > 1 ifTrue:
		[^0].
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self returnToExecutive: false postContextSwitch: true
		 "NOTREACHED"].
	self setMethod: (self iframeMethod: framePointer).
	instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
		[instructionPointer := self iframeSavedIP: framePointer].
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	self interpret.
	"NOTREACHED"
	^0
]

{ #category : #'process primitive support' }
CoInterpreterMT >> forceInterruptCheckFromHeartbeat [
	"Force an interrupt check ASAP. This version is the
	 entry-point to forceInterruptCheck for the heartbeat
	 timer to allow for repeatable debugging.

	 N.B. SYNCHRONIZE WITH deferStackLimitSmashAround:"
	suppressHeartbeatFlag ifFalse:
		[self checkForLongRunningPrimitive.
		 self sqLowLevelMFence.
		 deferSmash
			ifTrue:
				[deferredSmash := true.
				self sqLowLevelMFence]
			ifFalse:
				[self forceInterruptCheck.
				 self checkVMOwnershipFromHeartbeat]]
]

{ #category : #'internal interpreter access' }
CoInterpreterMT >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 These are the same as the image header flags shifted right two bits (excluding float order and full screen flags).
	 Bit 0: implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: if set, implies the GUI will run on the first thread and event queues will not be accessed from other threads
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued"
	^objectMemory integerObjectOf: (processHasThreadId ifTrue: [1] ifFalse: [0])
									+ (flagInterpretedMethods ifTrue: [2] ifFalse: [0])
									+ (preemptionYields ifTrue: [0] ifFalse: [4])
									+ (noThreadingOfGUIThread ifTrue: [8] ifFalse: [0])
									+ (newFinalization ifTrue: [16] ifFalse: [0])
									+ (imageHeaderFlags >> 2 bitClear: 1 + 2 + 4 + 8 + 16)
]

{ #category : #'image save/restore' }
CoInterpreterMT >> getImageHeaderFlags [
	"Answer the flags that are contained in the 7th long of the image header."
	^fullScreenFlag "0 or 1"
	+ (VMBIGENDIAN ifTrue: [0] ifFalse: [2]) "this is the imageFloatsLittleEndian flag"
	+ (processHasThreadId ifTrue: [4] ifFalse: [0])
	+ (flagInterpretedMethods ifTrue: [8] ifFalse: [0])
	+ (preemptionYields ifTrue: [0] ifFalse: [16r10])
	+ (noThreadingOfGUIThread ifTrue: [16r20] ifFalse: [0])
	+ (newFinalization ifTrue: [16r40] ifFalse: [0])
	+ (imageHeaderFlags bitClear: 16r7F) "these are any flags we do not recognize"
]

{ #category : #'process primitive support' }
CoInterpreterMT >> getMaxWaitingPriority [
	<cmacro: '() GIV(maxWaitingPriority)'>
	^maxWaitingPriority
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> inGUIThread [
	"The first thread is assumed to be the GUI thread, the VM thread that expects to receive
	 window events, etc.  This might appear to invite race conditions but it is only to be used
	 to decide whether to not give up the VM from the GUI thread (see disownVM:)."
	self assert: noThreadingOfGUIThread.
	^cogThreadManager getVMOwner = 1
]

{ #category : #initialization }
CoInterpreterMT >> initialEnterSmalltalkExecutive [
	"Main entry-point into the interpreter at system start-up."
	"Ensure that the myList of the activeProcess is nil.  Needed to load
	 old images which don't nil myList in transferTo:{from:}"
	objectMemory storePointerUnchecked: MyListIndex ofObject: self activeProcess withValue: objectMemory nilObject.
	cogThreadManager startThreadSubsystem.
	self threadSchedulingLoop: (cogThreadManager vmThreadAt: 1)
]

{ #category : #initialization }
CoInterpreterMT >> initialize [
	<doNotGenerate>
	super initialize.
	relinquishing := checkThreadActivation := deferThreadSwitch := false.
	foreignCallbackPriority := maxWaitingPriority := disownCount := willNotThreadWarnCount := 0
]

{ #category : #initialization }
CoInterpreterMT >> initializeInterpreter: bytesToShift [ 
	super initializeInterpreter: bytesToShift.
	foreignCallbackProcessSlot := (objectMemory lengthOf: objectMemory specialObjectsOop) > ForeignCallbackProcess
										ifTrue: [ForeignCallbackProcess]
										ifFalse: [NilObject]
]

{ #category : #simulation }
CoInterpreterMT >> initializeProcessorForThreadIndex: threadIndex [
	"Each simulated processor thread gets 4k of the rump C stack."
	<doNotGenerate>
	cogit initializeProcessorStack: (self cStackRangeForThreadIndex: threadIndex) last
]

{ #category : #'process primitive support' }
CoInterpreterMT >> isAffinedProcess: aProcess [
	^self isAffinedThreadId: (self ownerIndexOfProcess: aProcess)
]

{ #category : #'process primitive support' }
CoInterpreterMT >> isAffinedThreadId: threadId [
	^(objectMemory isIntegerObject: threadId)
	  and: [((objectMemory integerValueOf: threadId) bitAnd: 1) = 0]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> isBoundProcess: aProcess [
	^self isBoundThreadId: (self ownerIndexOfProcess: aProcess)
]

{ #category : #'process primitive support' }
CoInterpreterMT >> isBoundThreadId: threadId [
	^(objectMemory isIntegerObject: threadId)
	  and: [((objectMemory integerValueOf: threadId) bitAnd: 1) = 1]
]

{ #category : #simulation }
CoInterpreterMT >> isThreadedVM [
	<doNotGenerate>
	^true
]

{ #category : #'process primitive support' }
CoInterpreterMT >> isUnboundThreadId: threadId [
	"Answer if the threadId is neither affined nor bound.  Not the same as bound not."
	^threadId = objectMemory nilObject
	  or: [((objectMemory integerValueOf: threadId) bitAnd: (ThreadIdMask << 1) + 1) = 0]
]

{ #category : #initialization }
CoInterpreterMT >> loadInitialContext [
	| activeProc |
	super loadInitialContext.
	activeProc := self activeProcess.
	self assert: (self ownerIndexOfProcess: activeProc) = 0.
	activeProcessAffined := (self ownerIndexOfProcess: activeProc) ~= 0
]

{ #category : #'object memory support' }
CoInterpreterMT >> mapInterpreterOops [
	"Map all oops in the interpreter's state to their new values 
	 during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	<var: #vmThread type: #'CogVMThread *'>
	super mapInterpreterOops.

	"Per-thread state; trace each thread's own newMethod and stack of awol processes."
	1 to: cogThreadManager getNumThreads do:
		[:i| | vmThread |
		vmThread := cogThreadManager vmThreadAt: i.
		vmThread state ifNotNil:
			[(vmThread newMethodOrNull notNil
			 and: [objectMemory shouldRemapOop: vmThread newMethodOrNull]) ifTrue:
				[vmThread newMethodOrNull: (objectMemory remapObj: vmThread newMethodOrNull)].
			 0 to: vmThread awolProcIndex - 1 do:
				[:j|
				(objectMemory shouldRemapOop: (vmThread awolProcesses at: j)) ifTrue:
					[vmThread awolProcesses at: j put: (objectMemory remap: (vmThread awolProcesses at: j))]]]]
]

{ #category : #'object memory support' }
CoInterpreterMT >> markAndTraceInterpreterOops: fullGCFlag [
	"Mark and trace all oops in the interpreter's state."
	"Assume: All traced variables contain valid oops.
	 N.B. Don't trace messageSelector and lkupClass; these are ephemeral, live
	 only during message lookup and because createActualMessageTo will not
	 cause a GC these cannot change during message lookup."
	| oop |
	<var: #vmThread type: #'CogVMThread *'>
	"Must mark stack pages first to initialize the per-page trace
	 flags for full garbage collect before any subsequent tracing."
	self markAndTraceStackPages: fullGCFlag.
	self markAndTraceTraceLog.
	self markAndTracePrimTraceLog.
	objectMemory markAndTrace: objectMemory specialObjectsOop. "also covers nilObj, trueObj, falseObj, and compact classes"
	(objectMemory isImmediate: newMethod) ifFalse:
		[objectMemory markAndTrace: newMethod].
	self traceProfileState.
	tempOop = 0 ifFalse: [objectMemory markAndTrace: tempOop].
	tempOop2 = 0 ifFalse: [objectMemory markAndTrace: tempOop2].
	tempOop3 = 0 ifFalse: [objectMemory markAndTrace: tempOop3].

	1 to: objectMemory remapBufferCount do:
		[:i|
		oop := objectMemory remapBuffer at: i.
		(objectMemory isIntegerObject: oop) ifFalse:
			[objectMemory markAndTrace: oop]].

	"Callback support - trace suspended callback list - will be made per-thread soon"
	1 to: jmpDepth do:
		[:i|
		oop := suspendedCallbacks at: i.
		(objectMemory isIntegerObject: oop) ifFalse:
			[objectMemory markAndTrace: oop].
		oop := suspendedMethods at: i.
		(objectMemory isIntegerObject: oop) ifFalse:
			[objectMemory markAndTrace: oop]].

	"Per-thread state; trace each thread's own newMethod and stack of awol processes."
	1 to: cogThreadManager getNumThreads do:
		[:i| | vmThread |
		vmThread := cogThreadManager vmThreadAt: i.
		vmThread state notNil ifTrue:
			[vmThread newMethodOrNull notNil ifTrue:
				[objectMemory markAndTrace: vmThread newMethodOrNull].
			 0 to: vmThread awolProcIndex - 1 do:
				[:j|
				objectMemory markAndTrace: (vmThread awolProcesses at: j)]]]
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> ownVM: threadIndexAndFlags [
	<api>
	<inline: false>
	"This is the entry-point for plugins and primitives that wish to reacquire the VM after having
	 released it via disownVM or callbacks that want to acquire it without knowing their ownership
	 status.  This call will block until the VM is owned by the current thread or an error occurs.
	 The argument should be the value answered by disownVM, or 0 for callbacks that don't know
	 if they have disowned or not.  This is both an optimization to avoid having to query thread-
	 local storage for the current thread's index (since it can easily keep it in some local variable),
	 and a record of when an unbound process becomes affined to a thread for the dynamic
	 extent of some operation.

	 Answer 0 if the current thread is known to the VM.
	 Answer 1 if the current thread is unknown to the VM and takes ownership.
	 Answer -1 if the current thread is unknown to the VM and fails to take ownership."
	| threadIndex flags vmThread myProc activeProc sched |
	<var: #vmThread type: #'CogVMThread *'>
	threadIndexAndFlags = 0 ifTrue:
		[^self ownVMFromUnidentifiedThread].
	threadIndex := threadIndexAndFlags bitAnd: ThreadIdMask.
	flags := threadIndexAndFlags >> DisownFlagsShift.
	(flags anyMask: DisownVMForProcessorRelinquish) ifTrue:
		[relinquishing := false.
		 self sqLowLevelMFence].
	(threadIndexAndFlags anyMask: LockGUIThreadFlag) ifTrue:
		[self assert: (noThreadingOfGUIThread and: [self inGUIThread]).
		 self assert: disowningVMThread = nil.
		 (flags anyMask: DisownVMLockOutFullGC) ifTrue:
			[objectMemory decrementFullGCLock].
		 cogit recordEventTrace ifTrue:
			[self recordTrace: TraceOwnVM thing: ConstZero source: 0].
		 ^0].

	vmThread := cogThreadManager acquireVMFor: threadIndex.
	disownCount := disownCount - 1.

	(flags anyMask: DisownVMLockOutFullGC) ifTrue:
		[objectMemory decrementFullGCLock].
	disowningVMThread notNil ifTrue:
		[vmThread = disowningVMThread ifTrue:
			[self cCode: ''
				inSmalltalk:
					[| range |
					 range := self cStackRangeForThreadIndex: threadIndex.
					 self assert: (range includes: cogit getCStackPointer).
					 self assert: (range includes: cogit getCFramePointer)].
			 self assert: self successful.
			 self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject.
			 disowningVMThread := nil.
			 cogit recordEventTrace ifTrue:
				[self recordTrace: TraceOwnVM thing: ConstOne source: 0].
			 ^0].  "if not preempted we're done."
		self preemptDisowningThread].
	"We've been preempted; we must restore state and update the threadId
	 in our process, and may have to put the active process to sleep."
	sched := self schedulerPointer.
	activeProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: sched.
	(threadIndexAndFlags anyMask: OwnVMForeignThreadFlag)
		ifTrue:
			[self assert: foreignCallbackProcessSlot == ForeignCallbackProcess.
			 myProc := objectMemory splObj: foreignCallbackProcessSlot.
			self assert: myProc ~= objectMemory nilObject.
			objectMemory splObj: foreignCallbackProcessSlot put: objectMemory nilObject]
		ifFalse: [myProc := cogThreadManager popAWOLProcess: vmThread].
	self assert: activeProc ~= myProc.
	(activeProc ~= objectMemory nilObject
	 and: [(objectMemory fetchPointer: MyListIndex ofObject: activeProc) = objectMemory nilObject]) ifTrue:
		[self putToSleep: activeProc yieldingIf: preemptionYields].
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: myProc) = (objectMemory splObj: ProcessInExternalCodeTag).
	objectMemory
		storePointer: ActiveProcessIndex ofObject: sched withValue: myProc;
		storePointerUnchecked: MyListIndex ofObject: myProc withValue: objectMemory nilObject.
	"Only unaffine if the process was affined at this level and did not become bound in the interim."
	((threadIndexAndFlags anyMask: ProcessUnaffinedOnDisown)
	 and: [(self isBoundProcess: myProc) not]) ifTrue:
		[self setOwnerIndexOfProcess: myProc to: 0 bind: false].
	self initPrimCall.
	self externalSetStackPageAndPointersForSuspendedContextOfProcess: myProc.
	"If this primitive is called from machine code maintain the invariant that the return pc
	 of an interpreter callee calling a machine code caller is ceReturnToInterpreterPC."
	(vmThread inMachineCode
	 and: [instructionPointer >= objectMemory startOfMemory]) ifTrue:
		[self iframeSavedIP: framePointer put: instructionPointer.
		 instructionPointer := cogit ceReturnToInterpreterPC].
	newMethod := vmThread newMethodOrNull.
	argumentCount := vmThread argumentCount.
	self cCode:
			[self mem: reenterInterpreter
				cp: vmThread reenterInterpreter
				y: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[reenterInterpreter := vmThread reenterInterpreter].
	vmThread newMethodOrNull: nil.
	self cCode: ''
		inSmalltalk:
			[| range |
			 range := self cStackRangeForThreadIndex: threadIndex.
			 self assert: (range includes: vmThread cStackPointer).
			 self assert: (range includes: vmThread cFramePointer)].
	cogit setCStackPointer: vmThread cStackPointer.
	cogit setCFramePointer: vmThread cFramePointer.
	self assert: newMethod ~~ nil.
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceOwnVM thing: ConstTwo source: 0].
	^threadIndexAndFlags bitAnd: OwnVMForeignThreadFlag
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> ownVMFromUnidentifiedThread [
	"Attempt to take ownership from a thread that as yet doesn't know its index.
	 This supports callbacks where the callback could originate from any thread.
	
	 Answer 0 if the owning thread is known to the VM.
	 Answer 1 if the owning thread is unknown to the VM and now owns the VM.
	 Answer -1 if the owning thread is unknown to the VM and fails to own the VM.
	 Answer -2 if the owning thread is unknown to the VM and there is no foreign callback process installed."
	| count threadIndex vmThread |
	<var: #vmThread type: #'CogVMThread *'>
	<inline: false>
	(threadIndex := cogThreadManager ioGetThreadLocalThreadIndex) ~= 0 ifTrue:
		[ "this is a callback from a known thread"
		 threadIndex = cogThreadManager getVMOwner ifTrue: "the VM has not been disowned"
			[self assert: (disowningVMThread isNil or: [disowningVMThread = self currentVMThread]).
			 disowningVMThread := nil.
			 self currentVMThread state: CTMAssignableOrInVM.
			 ^VMAlreadyOwnedHenceDoNotDisown].
		 ^self ownVM: threadIndex].
	foreignCallbackPriority = 0 ifTrue:
		[^-2].
	count := 0.
	"If the current thread doesn't have an index it's new to the vm
	 and we need to allocate a new threadInfo, failing if we can't.
	 We also need a process in the foreignCallbackProcessSlot upon
	 which to run the thread's eventual callback."
	[[cogThreadManager tryLockVMToIndex: -1] whileFalse:
		[self waitingPriorityIsAtLeast: foreignCallbackPriority. 
		cogThreadManager ioTransferTimeslice].
	 (objectMemory splObj: foreignCallbackProcessSlot) ~= objectMemory nilObject] whileFalse:
		[cogThreadManager releaseVM.
		 (count := count + 1) > 1000 ifTrue:
			[^-2].
		 cogThreadManager ioMilliSleep: 1].
	vmThread := cogThreadManager unusedThreadInfo.
	"N.B.  Keep the VM locked anonymously so that we reserve the non-nil ForeignCallbackProcess
	for this thread, avoiding the race between competing foreign callbacks.  The acquireVMFor: in
	ownVM: will set the vmOwner to the actual index.  So only unlock on failure."
	vmThread isNil ifTrue:
		[cogThreadManager releaseVM.
		^-1].
	vmThread
		state: CTMWantingOwnership;
		priority: foreignCallbackPriority.
	cogThreadManager registerVMThread: vmThread.
	^self ownVM: vmThread index + OwnVMForeignThreadFlag
]

{ #category : #'process primitive support' }
CoInterpreterMT >> ownerIndexOfProcess: aProcess [
	^self ownerIndexOfThreadId: (self threadIdFieldOf: aProcess)
]

{ #category : #'process primitive support' }
CoInterpreterMT >> ownerIndexOfThreadId: threadId [
	^(objectMemory isIntegerObject: threadId)
		ifTrue: [(objectMemory integerValueOf: threadId) >> 1 bitAnd: ThreadIdMask]
		ifFalse: [0]
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> preemptDisowningThread [
	"Set the relevant state for disowningVMThread so that it can resume after
	 being preempted and set disowningVMThread to nil to indicate preemption.

	 N.B.  This should only be sent from checkPreemptionOfDisowningThread.

	 There are essentially four things to do.
	 a)	save the VM's notion of the current C stack pointers; these are pointers
		into a thread's stack and must be saved and restored in thread switch.
	 b)	save the VM's notion of the current Smalltalk execution point.  This is
		simply the suspend half of a process switch that saves the current context
		in the current process.
	 c)	add the process to the thread's set of AWOL processes so that the scheduler
		won't try to run the process while the thread has disowned the VM.
	 d)	save the in-primitive VM state, newMethod and argumentCount

	 ownVM: will restore the VM context as of disownVM: from the above when it
	 finds it has been preempted."

	| activeProc activeContext preemptedThread |
	<var: #preemptedThread type: #'CogVMThread *'>
	<inline: false>
	self assert: disowningVMThread notNil.
	self assert: (disowningVMThread state = CTMUnavailable
				or: [disowningVMThread state = CTMWantingOwnership]).
	self cCode: ''
		inSmalltalk:
			[| range |
			 range := self cStackRangeForThreadIndex: disowningVMThread index.
			 self assert: (range includes: cogit getCStackPointer).
			 self assert: (range includes: cogit getCFramePointer)].
	cogit recordEventTrace ifTrue:
		[self recordTrace: TracePreemptDisowningThread
			thing: (objectMemory integerObjectOf: disowningVMThread index)
			source: 0].
	disowningVMThread cStackPointer: cogit getCStackPointer.
	disowningVMThread cFramePointer: cogit getCFramePointer.
	activeProc := self activeProcess.
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: activeProc) = objectMemory nilObject.
	objectMemory
		storePointer: MyListIndex
		ofObject: activeProc
		withValue: (objectMemory splObj: ProcessInExternalCodeTag).
	"The instructionPointer must be pushed because the convention for inactive stack pages is that the
	 instructionPointer is top of stack.  We need to know if this primitive is called from machine code
	 because the invariant that the return pc of an interpreter callee calling a machine code caller is
	 ceReturnToInterpreterPC must be maintained."
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	objectMemory
		storePointer: SuspendedContextIndex
		ofObject: activeProc
		withValue: activeContext.
	"Since pushing the awol process may realloc disowningVMThread we need to reassign.
	 But since we're going to nil disowningVMThread anyway we can assign to a local."
	preemptedThread := cogThreadManager pushAWOLProcess: activeProc on: disowningVMThread.
	disowningVMThread := nil.
	preemptedThread priority: (self quickFetchInteger: PriorityIndex ofObject: activeProc).
	(self ownerIndexOfProcess: activeProc) = 0
		ifTrue: [self setOwnerIndexOfProcess: activeProc to: preemptedThread index bind: false]
		ifFalse: [self assert: (self ownerIndexOfProcess: activeProc) = preemptedThread index].
	preemptedThread
		newMethodOrNull: newMethod;
		argumentCount: argumentCount;
		inMachineCode: instructionPointer asUnsignedInteger <= objectMemory startOfMemory.
	self cCode:
			[self mem: preemptedThread reenterInterpreter
				cp: reenterInterpreter
				y: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[preemptedThread reenterInterpreter: reenterInterpreter]
]

{ #category : #'process primitives' }
CoInterpreterMT >> primitiveProcessBindToThreadId [
	"Attempt to bind the receiver to the thread with the id of the argument or nil, where the receiver is a Process.
	 If successful the VM will ensure that there are at least id many threads active."
	| aProcess id ec |
	<export: true>
	self cCode: [] inSmalltalk: [cogThreadManager isNil ifTrue: [^self primitiveFail]].
	id := self stackTop.
	aProcess := self stackValue: 1.
	((id = objectMemory nilObject or: [(objectMemory isIntegerObject: id)
										and: [(objectMemory integerValueOf: id) >= 0]])
	and: [(objectMemory isPointers: aProcess)
	and: [(objectMemory slotSizeOf: aProcess) >= (ThreadIdIndex + 1)]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	id := id = objectMemory nilObject ifTrue: [0] ifFalse: [objectMemory integerValueOf: id].
	id >= cogThreadManager maxNumThreads ifTrue:
		[^self primitiveFailFor: PrimErrLimitExceeded].
	(ec := self bindProcess: aProcess toId: id) ~= 0 ifTrue:
		[^self primitiveFailFor: ec].
	(aProcess = self activeProcess
	and: [(activeProcessAffined := id ~= 0)
	and: [id ~= cogThreadManager getVMOwner]]) ifTrue:
		[(self quickFetchInteger: PriorityIndex ofObject: aProcess) < maxWaitingPriority ifTrue:
			[maxWaitingPriority = self quickFetchInteger: PriorityIndex ofObject: aProcess].
		 checkThreadActivation := true.
		 self forceInterruptCheck].
	self pop: argumentCount
]

{ #category : #'process primitives' }
CoInterpreterMT >> primitiveProcessBoundThreadId [
	"Answer the receiver's current thread Id or nil, where the receiver is a Process."
	| aProcess id |
	<export: true>
	self cCode: [] inSmalltalk: [cogThreadManager isNil ifTrue: [^self primitiveFail]].
	aProcess := self stackTop.
	id := self ownerIndexOfProcess: aProcess.
	self pop: argumentCount + 1
		thenPush: (id = 0
						ifTrue: [objectMemory nilObject]
						ifFalse: [objectMemory integerObjectOf: id])
]

{ #category : #'I/O primitives' }
CoInterpreterMT >> primitiveRelinquishProcessor [
	"Relinquish the processor for up to the given number of microseconds.
	 The exact behavior of this primitive is platform dependent.
	 Override to check for waiting threads."

	| microSecs threadIndexAndFlags currentCStackPointer currentCFramePointer savedReenterInterpreter |
	<var: #currentCStackPointer type: #'void *'>
	<var: #currentCFramePointer type: #'void *'>
	<var: #savedReenterInterpreter type: #'jmp_buf'>
	microSecs := self stackTop.
	(objectMemory isIntegerObject: microSecs) ifFalse:
		[^self primitiveFail].
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject.
	self assert: relinquishing not.
	"DO NOT allow relinquishing the processor while we are profiling since this
	 may skew the time base for our measures (it may reduce processor speed etc).
	 Instead we go full speed, therefore measuring the precise time we spend in the
	 inner idle loop as a busy loop."
	nextProfileTick = 0 ifTrue:
		"Presumably we have nothing to do; this primitive is typically called from the
		 background process. So we should /not/ try and activate any threads in the
		 pool; they will waste cycles finding there is no runnable process, and will
		 cause a VM abort if no runnable process is found.  But we /do/ want to allow
		 FFI calls that have completed, or callbacks a chance to get into the VM; they
		 do have something to do.  DisownVMForProcessorRelinquish indicates this."
		[currentCStackPointer := cogit getCStackPointer.
		 currentCFramePointer := cogit getCFramePointer.
		 self cCode:
			[self mem: savedReenterInterpreter asVoidPointer
				cp: reenterInterpreter
				y: (self sizeof: #'jmp_buf')].
		 threadIndexAndFlags := self disownVM: DisownVMForProcessorRelinquish.
		 self assert: relinquishing.
		 self ioRelinquishProcessorForMicroseconds: (objectMemory integerValueOf: microSecs).
		 self assert: relinquishing.
		 self ownVM: threadIndexAndFlags.
		 self assert: relinquishing not.
		 self assert: cogThreadManager currentVMThread state = CTMAssignableOrInVM.
		 self assert: currentCStackPointer = cogit getCStackPointer.
		 self assert: currentCFramePointer = cogit getCFramePointer.
		 self cCode:
			[self assert: (self mem: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
						cm: reenterInterpreter
						p: (self sizeof: #'jmp_buf')) = 0]].
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject.
	self pop: 1  "microSecs; leave rcvr on stack"
]

{ #category : #'process primitives' }
CoInterpreterMT >> primitiveVMCurrentThreadId [
	<export: true>
	"Answer the VM's current thread's Id"
	self cCode: [] inSmalltalk: [cogThreadManager isNil ifTrue: [^self primitiveFail]].
	self pop: 1 thenPushInteger: cogThreadManager getVMOwner
]

{ #category : #'debug support' }
CoInterpreterMT >> printLogEntryAt: i [
	<inline: false>
	| intOrClass selectorOrMethod source |
	intOrClass := traceLog at: i.
	selectorOrMethod := traceLog at: i + 1.
	self printNum: ((traceLog at: i + 2) bitShift: -16); space.
	source := (traceLog at: i + 2) bitAnd: 16rFFFF.
	source <= TraceIsFromInterpreter ifTrue:
		[self print: (traceSources at: source); space].
	(objectMemory isIntegerObject: intOrClass)
		ifTrue:
			[| value |
			value := objectMemory integerValueOf: selectorOrMethod.
			intOrClass = TraceContextSwitch ifTrue:
				[self print: 'context switch'].
			 intOrClass = TraceBlockActivation ifTrue:
				[self print: ' [] in '; printHex: selectorOrMethod].
			 intOrClass = TraceBlockCreation ifTrue:
				[self print: 'create [] '; printHex: selectorOrMethod].
			 intOrClass = TraceIncrementalGC ifTrue:
				[self print: 'incrementalGC'].
			 intOrClass = TraceFullGC ifTrue:
				[self print: 'fullGC'].
			 intOrClass = TraceCodeCompaction ifTrue:
				[self print: 'compactCode'].
			 intOrClass = TraceVMCallback ifTrue:
				[self print: 'callback'].
			 intOrClass = TraceVMCallbackReturn ifTrue:
				[self print: 'return from callback'].
			 intOrClass = TraceThreadSwitch ifTrue:
				[self print: 'thread switch '; printNum: (value bitAnd: 16rFFFF); print: '->'; printNum: (value >> 16)].
			 intOrClass = TracePreemptDisowningThread ifTrue:
				[self print: 'preempt thread '; printNum: value].
			 intOrClass = TraceOwnVM ifTrue:
				[self print: 'ownVM '; printNum: value].
			 intOrClass = TraceDisownVM ifTrue:
				[self print: 'disownVM '; printHex: value]]
		ifFalse:
			[self space; printNameOfClass: intOrClass count: 5; print: '>>'; printStringOf: selectorOrMethod].
	source > TraceIsFromInterpreter ifTrue:
		[self space; print: (traceSources at: source)].
	self cr
]

{ #category : #'debug support' }
CoInterpreterMT >> recordThreadSwitchTo: ownerIndex source: sourceCode [
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceThreadSwitch
			thing: (objectMemory integerObjectOf: (ownerIndex << 16) + cogThreadManager getVMOwner)
			source: sourceCode]
]

{ #category : #'debug support' }
CoInterpreterMT >> recordTrace: classOrInteger thing: selector source: source [
	traceLog at: traceLogIndex put: classOrInteger.
	traceLog at: traceLogIndex + 1 put: selector.
	traceLog at: traceLogIndex + 2 put: source + (cogThreadManager getVMOwner bitShift: 16).
	traceLogIndex := traceLogIndex + 3 \\ TraceBufferSize
]

{ #category : #'process primitive support' }
CoInterpreterMT >> returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: source [
	| savedReenterInterpreter |
	<var: #savedReenterInterpreter type: #'jmp_buf'>
	<var: #vmThread type: #'CogVMThread *'>
	<inline: false>
	self cCode:
			[self flag: 'this is just for debugging.  Note the current C stack pointers'.
			 cogThreadManager currentVMThread
				cStackPointer: cogit getCStackPointer;
				cFramePointer: cogit getCFramePointer]
		inSmalltalk:
			[| range |
			 range := self cStackRangeForThreadIndex: cogThreadManager getVMOwner.
			 self assert: (range includes: cogit getCStackPointer).
			 self assert: (range includes: cogit getCFramePointer)].
	"We must use a copy of reenterInterpreter since we're giving up the VM to another vmThread."
	self cCode:
			[self mem: savedReenterInterpreter asVoidPointer
				cp: reenterInterpreter
				y: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[savedReenterInterpreter := reenterInterpreter].
	self recordThreadSwitchTo: (vmThread ifNotNil: [vmThread index] ifNil: [0]) source: source.
	vmThread
		ifNotNil: [cogThreadManager wakeVMThreadFor: vmThread index]
		ifNil: [cogThreadManager releaseVM].
	"2 implies returning to the threadSchedulingLoop."
	self siglong: savedReenterInterpreter jmp: ReturnToThreadSchedulingLoop
]

{ #category : #'callback support' }
CoInterpreterMT >> sendInvokeCallbackContext: vmCallbackContext [
	"Override to add sanity assertions."
	self assertSaneThreadAndProcess.
	^super sendInvokeCallbackContext: vmCallbackContext
]

{ #category : #'internal interpreter access' }
CoInterpreterMT >> setCogVMFlags: flags [
	"Set an array of flags indicating various properties of the Cog VM.
	 Bit 0: if set, implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: if set, implies a threaded VM will not dosown the VM if owned by the GUI thread
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued"
	flags asUnsignedInteger > 31 ifTrue:
		[^self primitiveFailFor: PrimErrUnsupported].
	processHasThreadId := (flags bitAnd: 1) ~= 0.
	flagInterpretedMethods := (flags bitAnd: 2) ~= 0.
	preemptionYields := (flags bitAnd: 4) = 0.
	noThreadingOfGUIThread := (flags bitAnd: 8) ~= 0.
	newFinalization := (flags bitAnd: 16) ~= 0
]

{ #category : #'image save/restore' }
CoInterpreterMT >> setImageHeaderFlagsFrom: headerFlags [
	"Set the flags that are contained in the 7th long of the image header."
	imageHeaderFlags := headerFlags. "so as to preserve unrecognised flags."
	fullScreenFlag := headerFlags bitAnd: 1.
	imageFloatsBigEndian := (headerFlags bitAnd: 2) = 0 ifTrue: [1] ifFalse: [0].
	processHasThreadId := (headerFlags bitAnd: 4) ~= 0.
	flagInterpretedMethods := (headerFlags bitAnd: 8) ~= 0.
	preemptionYields := (headerFlags bitAnd: 16) = 0.
	noThreadingOfGUIThread := (headerFlags bitAnd: 32) ~= 0.
	newFinalization := (headerFlags bitAnd: 64) ~= 0.

	processHasThreadId ifFalse:
		[self print: 'warning, processHasThreadId flag is unset; cannot function as a threaded VM if so.'; cr]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> setMaxWaitingPriorityTo: minPriority [
	maxWaitingPriority := minPriority
]

{ #category : #'process primitive support' }
CoInterpreterMT >> setOwnerIndexOfProcess: aProcess to: anIndex bind: bind [
	| threadId |
	threadId := anIndex = 0
				ifTrue: [objectMemory nilObject]
				ifFalse: [objectMemory integerObjectOf: (anIndex << 1) + (bind ifTrue: [1] ifFalse: [0])].
	objectMemory storePointerUnchecked: ThreadIdIndex ofObject: aProcess withValue: threadId
]

{ #category : #'process primitive support' }
CoInterpreterMT >> threadIdFieldOf: aProcess [
	^processHasThreadId
		ifTrue: [objectMemory fetchPointer: ThreadIdIndex ofObject: aProcess]
		ifFalse: [objectMemory nilObject]
]

{ #category : #accessing }
CoInterpreterMT >> threadManager [
	<doNotGenerate>
	^cogThreadManager
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> threadSchedulingLoop: vmThread [
	"Enter a loop attempting to run the VM with the highest priority process and
	 blocking on the thread's OS semaphore when unable to run that process.
	 We will return to this via threadSwitchIfNecessary:from: which is called in the
	 middle of transferTo:from: once the active process has been stored in the scheduler."
	<var: #vmThread type: #'CogVMThread *'>
	| attemptToRun |
	<inline: false>
	[self assert: vmThread state = CTMAssignableOrInVM.
	 attemptToRun := false.
	 (cogThreadManager getVMOwner = vmThread index)
		ifTrue: [attemptToRun := true]
		ifFalse:
			[(cogThreadManager tryLockVMToIndex: vmThread index) ifTrue:
				["If relinquishing is true, then primitiveRelinquishProcessor has disowned the
				  VM and only a returning call or callback should take ownership in that case."
				 relinquishing
					ifTrue: [cogThreadManager releaseVM]
					ifFalse: [attemptToRun := true]]].
	 attemptToRun ifTrue:
		[self tryToExecuteSmalltalk: vmThread].
	 (cogThreadManager testVMOwnerIs: vmThread index) ifFalse:
		[cogThreadManager waitForWork: vmThread].
	 true] whileTrue
]

{ #category : #'process primitive support' }
CoInterpreterMT >> threadSwitchIfNecessary: newProc from: sourceCode [
	"Invoked from transferTo:from: to switch threads if the new process is bound or affined to some other thread."
	| newProcThreadId vmThread activeContext tlti vmo |
	<var: #vmThread type: #'CogVMThread *'>
	self cCode: []
		inSmalltalk:
			[vmo := cogThreadManager getVMOwner.
			 tlti := cogThreadManager ioGetThreadLocalThreadIndex.
			 self assert: vmo = tlti].
	deferThreadSwitch ifTrue: [^self].
	newProcThreadId := self ownerIndexOfProcess: newProc.
	((activeProcessAffined := newProcThreadId ~= 0)
	 and: [newProcThreadId ~= cogThreadManager getVMOwner]) ifTrue:
		[self cCode: ''
			inSmalltalk:
				[self transcript ensureCr; nextPutAll: #threadSwitchIfNecessary:from:; space; print: newProc;
								space; print: vmo; nextPutAll: '->'; print: newProcThreadId; cr; flush].
		 "If primitiveProcessBindToThreadId has bound a process and indicated a thread
		  switch is necessary we'll come in here but the activeProcess won't have a
		  context yet, and it needs one from which the new thread can resume execution."
		 (objectMemory fetchPointer: SuspendedContextIndex ofObject: newProc) = objectMemory nilObject ifTrue:
			[self assert: newProc = self activeProcess.
			 self push: instructionPointer.
			 self externalWriteBackHeadFramePointers.
			 activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
			 objectMemory storePointer: SuspendedContextIndex ofObject: newProc withValue: activeContext].
		 vmThread := cogThreadManager vmThreadAt: newProcThreadId.
		 vmThread priority: (self quickFetchInteger: PriorityIndex ofObject: newProc).
		 vmThread state = CTMUnavailable ifTrue:
				[vmThread state: CTMWantingOwnership].
		 self returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: CSSwitchIfNeccessary].
	(self quickFetchInteger: PriorityIndex ofObject: newProc) < maxWaitingPriority ifTrue:
		[checkThreadActivation := true.
		 self forceInterruptCheck]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> transferTo: newProc from: sourceCode [
	"Record a process to be awoken on the next interpreter cycle.  Override to
	 potentially switch threads either if the new process is bound to another thread,
	 or if there is no runnable process but there is a waiting thread. Note that the
	 abort on no runnable process has beeen moved here from wakeHighestPriority."
	| sched oldProc activeContext vmThread |
	<inline: false>
	<var: #vmThread type: #'CogVMThread *'>
	statProcessSwitch := statProcessSwitch + 1.
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	"ensureMethodIsCogged: in makeBaseFrameFor: in
	 externalSetStackPageAndPointersForSuspendedContextOfProcess:
	 below may do a code compaction. Nil instructionPointer to avoid it getting pushed twice."
	instructionPointer := 0.
	sched := self schedulerPointer.
	oldProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: sched.
	self recordContextSwitchFrom: oldProc in: sourceCode.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	objectMemory storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.

	newProc isNil ifTrue:
		["Two possibilities.  One, there is at least one thread waiting to own the VM in which
		  case it should be activated.  Two, there are no processes to run and so abort."
		 vmThread := self willingVMThread.
		 (vmThread notNil and: [vmThread state = CTMWantingOwnership]) ifTrue:
			[self returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: sourceCode].
		self error: 'scheduler could not find a runnable process'].

	objectMemory storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	objectMemory storePointerUnchecked: MyListIndex ofObject: newProc withValue: objectMemory nilObject.

	self threadSwitchIfNecessary: newProc from: sourceCode.

	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc
]

{ #category : #'vm scheduling' }
CoInterpreterMT >> tryToExecuteSmalltalk: vmThread [
	"Attempt to run the current process, if it exists, on the given vmThread."
	<var: #vmThread type: #'CogVMThread *'>
	| dvmt activeProc ownerIndex |
	<var: #dvmt type: #'CogVMThread *'>
	self assert: cogThreadManager getVMOwner = vmThread index.
	self assert: cogThreadManager ioGetThreadLocalThreadIndex = vmThread index.
	dvmt := disowningVMThread.
	disowningVMThread
		ifNil: [activeProc := self activeProcess]
		ifNotNil:
			[self preemptDisowningThread.
			 activeProc := self wakeHighestPriority.
			 activeProc
				ifNil: [activeProc := objectMemory nilObject]
				ifNotNil: [objectMemory
							storePointerUnchecked: MyListIndex
							ofObject: activeProc
							withValue: objectMemory nilObject].
			 objectMemory
				storePointer: ActiveProcessIndex
				ofObject: self schedulerPointer
				withValue: activeProc].
	activeProc = objectMemory nilObject ifTrue:
		[cogThreadManager releaseVM.
		 ^nil].
	ownerIndex := self ownerIndexOfProcess: activeProc.
	(ownerIndex = 0
	 or: [ownerIndex ~= 0 and: [ownerIndex = cogThreadManager getVMOwner]])
		ifTrue:
			[self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject.
			 (objectMemory fetchPointer: SuspendedContextIndex ofObject: activeProc) ~= objectMemory nilObject ifTrue:
				[self externalSetStackPageAndPointersForSuspendedContextOfProcess: activeProc].
			 self enterSmalltalkExecutive.
			 "When we return here we should have already given up
			  the VM and so we cannot touch any interpreter state."]
		ifFalse:
			[cogThreadManager wakeVMThreadFor: ownerIndex]
]

{ #category : #'cog jit support' }
CoInterpreterMT >> vmOwnerLockAddress [
	<api> "NB. For the JIT only, so it can generate the lock & unlock functions."
	<returnTypeC: #usqInt>
	^processHasThreadId
		ifTrue: [self cCode: '(usqInt)&GIV(vmOwnerLock)'
					inSmalltalk: [self inMemoryVMOwnerLockAddress]]
		ifFalse: [0]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> waitingPriorityIsAtLeast: minPriority [
	"Set the maxWaitingPriority to at least minPriority on behalf
	 of a thread wanting to acquire the VM.  If maxWaitingPriority
	 is increased, schedule a thread activation check asap."
	maxWaitingPriority < minPriority ifTrue:
		[maxWaitingPriority := minPriority.
		 checkThreadActivation := true.
		 self forceInterruptCheck]
]

{ #category : #'process primitive support' }
CoInterpreterMT >> wakeHighestPriority [
	"Return the highest priority process that is ready to run.
	 To save time looking at many empty lists before finding a
	 runnable process the VM maintains a variable holding the
	 highest priority runnable process.  If this variable is 0 then the
	 VM does not know the highest priority and must search all lists.

	 Override to answer nil when there is no runnable process instead of
	 aborting.  In the threaded VM the abort test is done in transferTo:from:
	 becaue there may be some thread waiting to own the VM.  The transfer
	 to the thread shouldn't be done here because not all clients call this in
	 the right context (allowing a longjmp back to the threadSchedulingLoop)."
	| schedLists p processList proc ctxt |
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory numSlotsOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	[(p := p - 1) >= 0] whileTrue:
		[processList := objectMemory fetchPointer: p ofObject: schedLists.
	 	 [self isEmptyList: processList] whileFalse:
			["Only answer processes with a runnable suspendedContext.
			  Discard those that aren't; the VM would crash otherwise."
			 proc := self removeFirstLinkOfList: processList.
			 ctxt := objectMemory fetchPointer: SuspendedContextIndex ofObject: proc.
			 (self isLiveContext: ctxt) ifTrue:
				[highestRunnableProcessPriority := p + 1.
				^proc].
			 self warning: 'evicted zombie process from run queue']].
	^nil
]
