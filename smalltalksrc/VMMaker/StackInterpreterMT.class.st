Class {
	#name : #StackInterpreterMT,
	#superclass : #StackInterpreterPrimitives,
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
		'noThreadingOfGUIThread',
		'ownVMCount'
	],
	#classVars : [
		'CSCallbackEnter',
		'CSCallbackLeave',
		'CSCheckEvents',
		'CSEnterCriticalSection',
		'CSExitCriticalSection',
		'CSOwnVM',
		'CSResume',
		'CSSignal',
		'CSSuspend',
		'CSSwitchIfNeccessary',
		'CSThreadBind',
		'CSThreadSchedulingLoop',
		'CSWait',
		'CSYield',
		'DisownFlagsShift',
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
StackInterpreterMT class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^super ancilliaryClasses, { CogThreadManager. CogVMThread }
]

{ #category : #translation }
StackInterpreterMT class >> apiExportHeaderName [
	^'cointerpmt.h'
]

{ #category : #translation }
StackInterpreterMT class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		addHeaderFile:'"sqAtomicOps.h"'. "For THRLOG"
	aCCodeGenerator vmClass
		declareInterpreterVersionIn: aCCodeGenerator
		defaultName: 'Cog MT'.
	aCCodeGenerator
		var: #disowningVMThread type: #'CogVMThread *';
		var: #vmOwnerLock type: #'pthread_mutex_t'
]

{ #category : #initialization }
StackInterpreterMT class >> initializeBytecodeTableForSistaV1 [
	super initializeBytecodeTableForSistaV1.
	COGMTVM
		ifTrue: [ PrimitiveTable
				at: 227 + 1 put: #primitiveVMCurrentThreadId;
				at: 228 + 1 put: #primitiveProcessBoundThreadId;
				at: 229 + 1 put: #primitiveProcessBindToThreadId ]
]

{ #category : #initialization }
StackInterpreterMT class >> initializeMiscConstants [

	super initializeMiscConstants.

	"N.B. some of these DisownFlags are replicated in platforms/Cross/vm/sqVirtualMachine.h.
	 Hence they should always be initialized."
	DisownVMForProcessorRelinquish := 64.
	
	CSCallbackEnter := 3.
	CSCallbackLeave := 4.
	CSEnterCriticalSection := 5.
	CSExitCriticalSection := 6.
	CSResume := 7.
	CSSignal := 8.
	CSSuspend := 9.
	CSWait := 10.
	CSYield := 11.
	CSCheckEvents := 12.
	CSThreadSchedulingLoop := 13.
	CSOwnVM := 14.
	CSThreadBind := 15.
	CSSwitchIfNeccessary := 16.

	(InitializationOptions at: #COGMTVM ifAbsent: [false]) == false ifTrue:
		[^self].

	COGMTVM := true.
	CSCheckEvents := 12.
	CSSwitchIfNeccessary := 16.
	
	ReturnToThreadSchedulingLoop := 2 "setjmp/longjmp code."
]

{ #category : #initialization }
StackInterpreterMT class >> initializePrimitiveTable [
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
StackInterpreterMT class >> initializeSchedulerIndices [
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
StackInterpreterMT class >> interpreterVersion [ 
	^ 'Stack MT'
]

{ #category : #translation }
StackInterpreterMT class >> isNonArgumentImplicitReceiverVariableName: aString [
	^'cogThreadManager' = aString
	   or: [super isNonArgumentImplicitReceiverVariableName: aString]
]

{ #category : #testing }
StackInterpreterMT class >> isThreadedVM [
	^true
]

{ #category : #translation }
StackInterpreterMT class >> mustBeGlobal: var [
	"Make disownCount global so that debugging/instrumentation code can use it to check
	 if a threaded FFI call is in progress (i.e. this isn't necessary for production)"

	^(super mustBeGlobal: var)
	   or: [ #('disownCount' 'willNotThreadWarnCount') includes: var]
]

{ #category : #'accessing class hierarchy' }
StackInterpreterMT class >> primitivesClass [
	^StackInterpreterMT
]

{ #category : #translation }
StackInterpreterMT class >> sourceFileName [
	"Answer the filename for the core interpreter"

	^'cointerpmt.c'
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> activateNewClosure: blockClosure outer: outerContext method: theMethod  numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied closureIP switched |
	<inline: true>
	self assert: (objectMemory isContext: outerContext).
	numCopied := self copiedValueCountOfClosure: blockClosure.
	self assert: theMethod = (objectMemory fetchPointer: MethodIndex ofObject: outerContext).
	self assert: (objectMemory isOopCompiledMethod: theMethod).

	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	"Because inst var access is not checked, we must follow the receiver in Spur to ensure it is valid."
	self push: (objectMemory followField: ReceiverIndex ofObject: outerContext).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (objectMemory
					fetchPointer: i + ClosureFirstCopiedValueIndex
					ofObject: blockClosure)].

	self assert: (self frameIsBlockActivation: framePointer).
	self assert: (self frameHasContext: framePointer) not.

	"The initial instructions in the block nil-out remaining temps."

	"the instruction pointer is a pointer variable equal to 
	method oop + ip + BaseHeaderSize 
	-1 for 0-based addressing of fetchByte 
	-1 because it gets incremented BEFORE fetching currentByte"
	closureIP := self quickFetchInteger: ClosureStartPCIndex ofObject: blockClosure.
	instructionPointer := theMethod + closureIP + objectMemory baseHeaderSize - 2.
	self setMethod: theMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	switched := false.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch].
	self returnToExecutive: true postContextSwitch: switched
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> activateNewFullClosure: blockClosure method: theMethod numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied methodHeader numTemps switched |
	<inline: true>
	self assert: theMethod = (objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: blockClosure).
	numCopied := self copiedValueCountOfFullClosure: blockClosure.
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	"Because inst var access is not checked, we must follow the receiver in Spur to ensure it is valid."
	self push: (objectMemory followField: FullClosureReceiverIndex ofObject: blockClosure).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (objectMemory
					fetchPointer: i + FullClosureFirstCopiedValueIndex
					ofObject: blockClosure)].

	self assert: (self frameIsBlockActivation: framePointer).
	self assert: (self frameHasContext: framePointer) not.

	methodHeader := objectMemory methodHeaderOf: theMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.

	numArgs + numCopied + 1 to: numTemps do: [ :i | self push: objectMemory nilObject].

	instructionPointer := (self initialIPForHeader: methodHeader method: theMethod) - 1.
	
	self setMethod: theMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	switched := false.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch].
	self returnToExecutive: true postContextSwitch: switched
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> activateNewMethod [
	| methodHeader switched |
	methodHeader := self justActivateNewMethod: false. "either interpreted or machine code"

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	switched := true.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader)].
	self returnToExecutive: true postContextSwitch: switched
]

{ #category : #accessing }
StackInterpreterMT >> activateProcess: activeProc [

	objectMemory
		storePointerUnchecked: MyListIndex
		ofObject: activeProc
		withValue: objectMemory nilObject.
	objectMemory
		storePointer: ActiveProcessIndex
		ofObject: self schedulerPointer
		withValue: activeProc
]

{ #category : #'debug support' }
StackInterpreterMT >> assertSaneThreadAndProcess [
	<inline: true>
	self assert: cogThreadManager getVMOwner > 0.
	self assert: cogThreadManager currentVMThread state = CTMAssignableOrInVM.
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> baseFrameReturn [
	"Return from a baseFrame (the bottom frame in a stackPage).  The context to
	 return to (which may be married) is stored in the first word of the stack."
	<inline: true>
	| contextToReturnTo retToContext theFP theSP thePage newPage frameAbove |
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	contextToReturnTo := self frameCallerContext: localFP.

	"The stack page is effectively free now, so free it.  We must free it to be
	 correct in determining if contextToReturnTo is still married, and in case
	 makeBaseFrameFor: cogs a method, which may cause a code compaction,
	 in which case the frame must be free to avoid the relocation machinery
	 tracing the dead frame.  Since freeing now temporarily violates the page-list
	 ordering invariant, use the assert-free version."
	stackPages freeStackPageNoAssert: stackPage.
	retToContext := objectMemory isContext: contextToReturnTo.
	(retToContext
	 and: [self isStillMarriedContext: contextToReturnTo])
		ifTrue:
			[theFP := self frameOfMarriedContext: contextToReturnTo.
			 thePage := stackPages stackPageFor: theFP.
			 theFP = thePage headFP
				ifTrue:
					[theSP := thePage headSP]
				ifFalse:
					["Returning to some interior frame, presumably because of a sender assignment.
					  Move the frames above to another page (they may be in use, e.g. via coroutining).
					  Make the interior frame the top frame."
					 frameAbove := self findFrameAbove: theFP inPage: thePage.
					 "Since we've just deallocated a page we know that newStackPage won't deallocate an existing one."
					 newPage := stackPages newStackPage.
					 self assert: newPage = stackPage.
					 self moveFramesIn: thePage through: frameAbove toPage: newPage.
					 stackPages markStackPageMostRecentlyUsed: newPage.
					 theFP := thePage headFP.
					 theSP := thePage headSP]]
		ifFalse:
			[
			(retToContext
			  and: [objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[^self internalCannotReturn: localReturnValue].
			"We must void the instructionPointer to stop it being updated if makeBaseFrameFor:
			  cogs a method, which may cause a code compaction."
			 instructionPointer := 0.
			 thePage := self makeBaseFrameFor: contextToReturnTo.
			 theFP := thePage headFP.
			 theSP := thePage headSP].
	self setStackPageAndLimit: thePage.
	self assert: (stackPages stackPageFor: theFP) = stackPage.
	localSP := theSP.
	localFP := theFP.
	localIP := self pointerForOop: self internalStackTop.
	self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
	self setMethod: (self iframeMethod: localFP).
	self internalStackTopPut: localReturnValue.
	^self fetchNextBytecode
]

{ #category : #'process primitive support' }
StackInterpreterMT >> bindProcess: aProcess toId: newId [
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
	| threadId ownerIndex |
	processHasThreadId ifFalse:
		[^PrimErrUnsupported].

	threadId := self threadIdFieldOf: aProcess.
	ownerIndex := self ownerIndexOfThreadId: threadId.

	(self isAffinedThreadId: threadId) ifTrue:
		[(ownerIndex = newId
		  or: [newId = 0]) ifTrue:
			[^0].
		^PrimErrInappropriate].

	(cogThreadManager growThreadInfosToAtLeast: newId)
		ifFalse: [ ^ PrimErrLimitExceeded ].
	"newId > 0 ifTrue:
		[(cogThreadManager startThreadForThreadIndex: newId) ifFalse:
			[^PrimErrLimitExceeded]]."

	self setOwnerIndexOfProcess: aProcess to: newId bind: true.
	^0
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> callbackEnter: callbackID [
	"Re-enter the interpreter for executing a callback"
	| savedReenterInterpreter
	  wasInMachineCode calledFromMachineCode |
	<volatile>
	<export: true>
	<var: #callbackID type: #'sqInt *'>
	<var: #savedReenterInterpreter type: #'jmp_buf'>

	"For now, do not allow a callback unless we're in a primitiveResponse"
	(self asserta: primitiveFunctionPointer ~= 0) ifFalse:
		[^false].

	self assert: primFailCode = 0.

	"Check if we've exceeded the callback depth"
	(self asserta: jmpDepth < MaxJumpBuf) ifFalse:
		[^false].
	jmpDepth := jmpDepth + 1.

	wasInMachineCode := self isMachineCodeFrame: framePointer.
	calledFromMachineCode := instructionPointer <= objectMemory startOfMemory.

	"Suspend the currently active process"
	suspendedCallbacks at: jmpDepth put: self activeProcess.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	self flag: 'need to debug this properly.  Conceptually it is the right thing to do but it crashes in practice'.
	false
		ifTrue:
			["Signal external semaphores since a signalSemaphoreWithIndex: request may
			  have been issued immediately prior to this callback before the VM has any
			  chance to do a signalExternalSemaphores in checkForEventsMayContextSwitch:"
			 self signalExternalSemaphores.
			 "If no process is awakened by signalExternalSemaphores then transfer
			  to the highest priority runnable one."
			 (suspendedCallbacks at: jmpDepth) = self activeProcess ifTrue:
				[self transferTo: self wakeHighestPriority from: CSCallbackLeave]]
		ifFalse:
			[self transferTo: self wakeHighestPriority from: CSCallbackLeave].

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check as soon as possible."
	self forceInterruptCheck.

	"Save the previous CStackPointers and interpreter entry jmp_buf."
	self memcpy: savedReenterInterpreter asVoidPointer
		_: reenterInterpreter
		_: (self sizeof: #'jmp_buf').
	(self setjmp: (jmpBuf at: jmpDepth)) = 0 ifTrue: "Fill in callbackID"
		[callbackID at: 0 put: jmpDepth.
		 self enterSmalltalkExecutive.
		 self assert: false "NOTREACHED"].

	self memcpy: reenterInterpreter
		_: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
		_: (self sizeof: #'jmp_buf').

	"Transfer back to the previous process so that caller can push result"
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	self transferTo: (suspendedCallbacks at: jmpDepth) from: CSCallbackLeave.
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	argumentCount := self argumentCountOf: newMethod.
	self assert: wasInMachineCode = (self isMachineCodeFrame: framePointer).
	"Even if the context was flushed to the heap and rebuilt in transferTo:from:
	above it will remain an interpreted frame because the context's pc would
	remain a bytecode pc.  So the instructionPointer must also be a bytecode pc."
	self assert: (self isMachineCodeFrame: framePointer) not.
	self assert: instructionPointer > objectMemory startOfMemory.
	self assert: primFailCode = 0.
	jmpDepth := jmpDepth-1.
	^true
]

{ #category : #'process primitive support' }
StackInterpreterMT >> cedeToHigherPriorityThreads [
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
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	self putToSleep: activeProc yieldingIf: preemptionYields.
	"Transcript cr; print: #cedeToHighestPriorityThreadIfHigherThan:; cr.
	  self printExternalHeadFrame.
	  self print: 'ip: '; printHex: self instructionPointer. Transcript cr; flush."
	self returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: CSCheckEvents
]

{ #category : #'process primitive support' }
StackInterpreterMT >> checkForEventsMayContextSwitch: mayContextSwitch [
	"Check for possible interrupts and handle one if necessary.
	 Answer if a context switch has occurred."
	| switched sema now |
	<inline: false>
	<var: #now type: #usqLong>
	self assertSaneThreadAndProcess.
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
			[((now := self ioUTCMicroseconds) >= nextPollUsecs and: [ self inGUIThread ]) ifTrue:
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
StackInterpreterMT >> checkVMOwnershipFromHeartbeat [
	"Check whether the VM is unowned and needs to set a thread running to try and own it.
	 Do not attempt this if the image doesn't have a threadId inst var in Process; the VM
	 can't thread these images."
	<inline: false>
	self sqLowLevelMFence.
	"("processHasThreadId
	 "and: [cogThreadManager getVMOwner = 0]) "ifTrue:
		[cogThreadManager ensureRunningVMThread: relinquishing]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> disownVM: flags [
	"Release the VM to other threads and answer the current thread's index.
	 Currently valid flags:
		DisownVMLockOutFullGC	- prevent fullGCs while this thread disowns the VM
		DisownVMForFFICall			- informs the VM that it is entering an FFI call
		DisownVMForThreading		- informs the VM that it is entering an FFI call etc during which threading should be permitted
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
	^ self disownVM: flags fromVMThread: cogThreadManager currentVMThread.
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> disownVM: flags fromVMThread: vmThread [
	"Release the VM to other threads and answer the current thread's index.
	 Currently valid flags:
		DisownVMLockOutFullGC	- prevent fullGCs while this thread disowns the VM
		DisownVMForFFICall			- informs the VM that it is entering an FFI call
		DisownVMForThreading		- informs the VM that it is entering an FFI call etc during which threading should be permitted
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
	| result |
	<var: #vmThread type: #'CogVMThread *'>
	self assert: self successful.
	processHasThreadId ifFalse:
		[willNotThreadWarnCount < 10 ifTrue:
			[self print: 'warning: VM parameter 48 indicates Process doesn''t have threadId; VM will not thread'; cr.
			 willNotThreadWarnCount := willNotThreadWarnCount + 1]].
	(flags anyMask: VMAlreadyOwnedHenceDoNotDisown) ifTrue:
		[disowningVMThread := vmThread.
		 vmThread state: CTMUnavailable.
		 ^0].
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

{ #category : #accessing }
StackInterpreterMT >> disowningVMThread [
	<doNotGenerate>
	^ disowningVMThread
]

{ #category : #initialization }
StackInterpreterMT >> enterSmalltalkExecutive [
	"Main entry-point into the interpreter at each execution level, where an
	 execution level is either the start of execution or reentry for a callback."
	<cmacro: '() enterSmalltalkExecutiveImplementation()'>
	"Simulation of the setjmp in enterSmalltalkExecutiveImplementation for reentry
	 into interpreter.  Simulation of the register state switch on thread switch."
	| vmo tlti retVal |
	[vmo := cogThreadManager getVMOwner.
	 tlti := cogThreadManager ioGetThreadLocalThreadIndex.
	 self assert: vmo = tlti.
	 retVal := [self enterSmalltalkExecutiveImplementation]
				on: ReenterInterpreter
				do: [:ex|
					vmo := cogThreadManager getVMOwner.
					tlti := cogThreadManager ioGetThreadLocalThreadIndex.
					self assert: (ex returnValue = ReturnToThreadSchedulingLoop
								 or: [vmo = tlti]).
					ex return: ex returnValue].
	 retVal = ReturnToInterpreter] whileTrue
]

{ #category : #'callback support' }
StackInterpreterMT >> enterSmalltalkExecutiveFromCallback [
	<inline: true>
	self threadSchedulingLoop: cogThreadManager currentVMThread
]

{ #category : #initialization }
StackInterpreterMT >> enterSmalltalkExecutiveImplementation [
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
	"Setjmp for reentry into interpreter from elsewhere, e.g. machine-code trampolines."
	(self sigset: reenterInterpreter jmp: 0) > 1 ifTrue:
		[^0].
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self returnToExecutive: false postContextSwitch: true
		 "NOTREACHED"].
	self setMethod: (self iframeMethod: framePointer).
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	self interpret.
	"NOTREACHED"
	^0
]

{ #category : #'process primitive support' }
StackInterpreterMT >> forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter [
	"Do a returnToExecutive: inInterpreter postContextSwitch: true for a process primtive
	 being sure to sample the profile clock before making the switch."
	<inline: true>
	"If we are profiling, take accurate primitive measures"
	nextProfileTick > 0 ifTrue:
		[self checkProfileTick: newMethod].
	^self returnToExecutive: inInterpreter postContextSwitch: true
]

{ #category : #UI }
StackInterpreterMT >> forceInterruptCheckFromHeartbeat [
	"Force an interrupt check ASAP. This version is the
	 entry-point to forceInterruptCheck for the heartbeat
	 timer to allow for repeatable debugging.

	 N.B. SYNCHRONIZE WITH deferStackLimitSmashAround:"
	suppressHeartbeatFlag ifFalse:
		[self checkForLongRunningPrimitive.
		 self sqLowLevelMFence.
"		 deferSmash
			ifTrue:
				[deferredSmash := true.
				self sqLowLevelMFence]
			ifFalse:
				["self forceInterruptCheck.
				 self checkVMOwnershipFromHeartbeat"]"]
]

{ #category : #accessing }
StackInterpreterMT >> foreignCallbackProcessSlot: anInteger [ 
	foreignCallbackProcessSlot := anInteger
]

{ #category : #'internal interpreter access' }
StackInterpreterMT >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 These are the same as the image header flags shifted right two bits (excluding float order and full screen flags).
	 Bit 0: implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: if set, implies the GUI will run on the first thread and event queues will not be accessed from other threads
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued
	 Bit 5: if set, implies wheel events will be delivered as such and not mapped to arrow key events"
	^objectMemory integerObjectOf: (processHasThreadId ifTrue: [1] ifFalse: [0])
									+ (preemptionYields ifTrue: [0] ifFalse: [4])
									+ (noThreadingOfGUIThread ifTrue: [8] ifFalse: [0])
									+ (newFinalization ifTrue: [16] ifFalse: [0])
									+ (imageHeaderFlags >> 2 bitClear: 1 + 2 + 4 + 8 + 16)
]

{ #category : #'image save/restore' }
StackInterpreterMT >> getImageHeaderFlags [
	"Answer the flags that are contained in the 7th long of the image header."
	1halt.
	^fullScreenFlag "0 or 1"
	+ (VMBIGENDIAN ifTrue: [0] ifFalse: [2]) "this is the imageFloatsLittleEndian flag"
	+ (processHasThreadId ifTrue: [4] ifFalse: [0])
	+ (preemptionYields ifTrue: [0] ifFalse: [16r10])
	+ (noThreadingOfGUIThread ifTrue: [16r20] ifFalse: [0])
	+ (newFinalization ifTrue: [16r40] ifFalse: [0])
	+ (sendWheelEvents ifTrue: [16r80] ifFalse: [0])
	+ (imageHeaderFlags bitClear: 16rFF) "these are any flags we do not recognize"
]

{ #category : #'process primitive support' }
StackInterpreterMT >> getMaxWaitingPriority [
	<cmacro: '() GIV(maxWaitingPriority)'>
	^maxWaitingPriority
]

{ #category : #'process primitive support' }
StackInterpreterMT >> getVMSpecialObject: aVMObjectClass atIndex: anIndex [

	^ self
		cCode: [ objectMemory splObj: anIndex ]
		inSmalltalk: [ 
			aVMObjectClass
				objectMemory: objectMemory
				address: (objectMemory splObj: anIndex) ]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> ifBackwardsCheckForEvents: offset [
	"Backward jump means we're in a loop; check for possible interrupts."
	<inline: true>
	(offset < 0
	 and: [localSP < stackLimit]) ifTrue:
		[ | switched |
		 self externalizeIPandSP.
		 switched := self checkForEventsMayContextSwitch: true.
   		 self returnToExecutive: true postContextSwitch: switched.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> inGUIThread [
	"The first thread is assumed to be the GUI thread, the VM thread that expects to receive
	 window events, etc.  This might appear to invite race conditions but it is only to be used
	 to decide whether to not give up the VM from the GUI thread (see disownVM:)."
	^cogThreadManager getVMOwner = 1
]

{ #category : #initialization }
StackInterpreterMT >> initialEnterSmalltalkExecutive [
	"Main entry-point into the interpreter at system start-up."
	"Ensure that the myList of the activeProcess is nil.  Needed to load
	 old images which don't nil myList in transferTo:{from:}"
	objectMemory storePointerUnchecked: MyListIndex ofObject: self activeProcess withValue: objectMemory nilObject.
	self initializeVMOwnerLock.
	cogThreadManager startThreadSubsystem.
	self threadSchedulingLoop: (cogThreadManager vmThreadAt: 1)
]

{ #category : #initialization }
StackInterpreterMT >> initialize [
	super initialize.
	relinquishing := checkThreadActivation := deferThreadSwitch := false.
	foreignCallbackPriority := maxWaitingPriority := disownCount := willNotThreadWarnCount := ownVMCount := 0.
	
	self
		cCode: 'pthread_mutex_init(&vmOwnerLock, NULL)'
		inSmalltalk: [ self threadManager vmOwnerLock: Mutex new ]
]

{ #category : #initialization }
StackInterpreterMT >> initializeInterpreter: bytesToShift [ 
	super initializeInterpreter: bytesToShift.
	foreignCallbackProcessSlot := (objectMemory lengthOf: objectMemory specialObjectsOop) > ForeignCallbackProcess
										ifTrue: [ForeignCallbackProcess]
										ifFalse: [NilObject]
]

{ #category : #simulation }
StackInterpreterMT >> initializeProcessorForThreadIndex: threadIndex [
	"Each simulated processor thread gets 4k of the rump C stack."
	<doNotGenerate>

]

{ #category : #initialization }
StackInterpreterMT >> initializeVMOwnerLock [
	self
		cCode: 'pthread_mutex_init(&vmOwnerLock, NULL)'
		inSmalltalk: [ self halt ]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> internalActivateNewMethod [
	| methodHeader numTemps rcvr switched |
	<inline: true>

	methodHeader := objectMemory methodHeaderOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	self assert: argumentCount = (self argumentCountOfMethodHeader: methodHeader).
	rcvr := self internalStackValue: argumentCount. "could new rcvr be set at point of send?"
	self assert: (objectMemory isOopForwarded: rcvr) not.

	self internalPush: localIP.
	self internalPush: localFP.
	localFP := localSP.
	self internalPush: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self internalPush: (self
						encodeFrameFieldHasContext: false
						isBlock: false
						numArgs: (self argumentCountOfMethodHeader: methodHeader)).
	self internalPush: objectMemory nilObject. "FxThisContext field"
	self internalPush: rcvr.

	"Initialize temps..."
	argumentCount + 1 to: numTemps do:
		[:i | self internalPush: objectMemory nilObject].

	"-1 to account for pre-increment in fetchNextBytecode"
	localIP := self pointerForOop: (self initialIPForHeader: methodHeader method: newMethod) - 1.

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 localIP := localIP + (self sizeOfCallPrimitiveBytecode: methodHeader).
		 primFailCode ~= 0 ifTrue:
			[self reapAndResetErrorCodeTo: localSP header: methodHeader]].

	self assert: (self frameNumArgs: localFP) = argumentCount.
	self assert: (self frameIsBlockActivation: localFP) not.
	self assert: (self frameHasContext: localFP) not.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	localSP < stackLimit ifTrue:
		[self externalizeIPandSP.
		 switched := self handleStackOverflowOrEventAllowContextSwitch:
						(self canContextSwitchIfActivating: newMethod header: methodHeader).
		 self returnToExecutive: true postContextSwitch: switched.
		 self internalizeIPandSP]
]

{ #category : #'process primitive support' }
StackInterpreterMT >> isAffinedProcess: aProcess [
	^self isAffinedThreadId: (self ownerIndexOfProcess: aProcess)
]

{ #category : #'process primitive support' }
StackInterpreterMT >> isAffinedThreadId: threadId [
	^(objectMemory isIntegerObject: threadId)
	  and: [((objectMemory integerValueOf: threadId) bitAnd: 1) = 0]
]

{ #category : #'process primitive support' }
StackInterpreterMT >> isBoundProcess: aProcess [
	^self isBoundThreadId: (self ownerIndexOfProcess: aProcess)
]

{ #category : #'process primitive support' }
StackInterpreterMT >> isBoundThreadId: threadId [
	^(objectMemory isIntegerObject: threadId)
	  and: [((objectMemory integerValueOf: threadId) bitAnd: 1) = 1]
]

{ #category : #simulation }
StackInterpreterMT >> isThreadedVM [
	<doNotGenerate>
	^true
]

{ #category : #'process primitive support' }
StackInterpreterMT >> isUnboundThreadId: threadId [
	"Answer if the threadId is neither affined nor bound.  Not the same as bound not."
	^threadId = objectMemory nilObject
	  or: [((objectMemory integerValueOf: threadId) bitAnd: (ThreadIdMask << 1) + 1) = 0]
]

{ #category : #initialization }
StackInterpreterMT >> loadInitialContext [
	| activeProc |
	super loadInitialContext.
	activeProc := self activeProcess.
	self assert: (self ownerIndexOfProcess: activeProc) = 0.
	activeProcessAffined := (self ownerIndexOfProcess: activeProc) ~= 0
]

{ #category : #'object memory support' }
StackInterpreterMT >> mapInterpreterOops [
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
					[vmThread awolProcesses at: j put: (objectMemory remapObj: (vmThread awolProcesses at: j))]]]]
]

{ #category : #'object memory support' }
StackInterpreterMT >> markAndTraceInterpreterOops: fullGCFlag [
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
StackInterpreterMT >> ownVM: threadIndexAndFlags [
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
		 ^0].

	vmThread := cogThreadManager acquireVMFor: threadIndex.
	disownCount := disownCount - 1.

	(flags anyMask: DisownVMLockOutFullGC) ifTrue:
		[objectMemory decrementFullGCLock].
	disowningVMThread notNil ifTrue:
		[vmThread = disowningVMThread ifTrue:
			[self assert: self successful.
			 self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject.
			 disowningVMThread := nil.
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
	newMethod := vmThread newMethodOrNull.
	argumentCount := vmThread argumentCount.
	self cCode:
			[self memcpy: reenterInterpreter
				_: vmThread reenterInterpreter
				_: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[reenterInterpreter := vmThread reenterInterpreter].
	vmThread newMethodOrNull: nil.
	self assert: newMethod ~~ nil.
	^threadIndexAndFlags bitAnd: OwnVMForeignThreadFlag
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> ownVMFromUnidentifiedThread [
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
StackInterpreterMT >> ownerIndexOfProcess: aProcess [
	^self ownerIndexOfThreadId: (self threadIdFieldOf: aProcess)
]

{ #category : #'process primitive support' }
StackInterpreterMT >> ownerIndexOfThreadId: threadId [
	^(objectMemory isIntegerObject: threadId)
		ifTrue: [(objectMemory integerValueOf: threadId) >> 1 bitAnd: ThreadIdMask]
		ifFalse: [0]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> preemptDisowningThread [
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
			[self memcpy: preemptedThread reenterInterpreter
				_: reenterInterpreter
				_: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[preemptedThread reenterInterpreter: reenterInterpreter]
]

{ #category : #accessing }
StackInterpreterMT >> preemptionYields: aBoolean [
	<doNotGenerate>
	
	preemptionYields := aBoolean
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveEnterCriticalSection [
	"Attempt to enter a CriticalSection/Mutex.  If not owned, set the owner to the current
	 process and answer false. If owned by the current process  answer true.   Otherwise
	 suspend the process.  Answer if the receiver is owned by the current process."
	| criticalSection owningProcessIndex owningProcess activeProc inInterpreter |
	argumentCount > 0
		ifTrue:
			[criticalSection := self stackValue: 1.  "rcvr"
			 activeProc := self stackTop]
		ifFalse:
			[criticalSection := self stackTop.  "rcvr"
			 activeProc := self activeProcess].
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := objectMemory fetchPointer: owningProcessIndex ofObject: criticalSection.
	owningProcess = objectMemory nilObject ifTrue:
		[objectMemory storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: argumentCount + 1 thenPush: objectMemory falseObject].
	owningProcess = activeProc ifTrue:
		[^self pop: argumentCount + 1 thenPush: objectMemory trueObject].
	"Arrange to answer false (unowned) when the process is resumed."
	self pop: argumentCount + 1 thenPush: objectMemory falseObject.
	"We're going to switch process, either to an interpreted frame or a machine
	 code frame. To know whether to return or enter machine code we have to
	 know from whence we came.  We could have come from the interpreter,
	 either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	self addLastLink: activeProc toList: criticalSection.
	self transferTo: self wakeHighestPriority from: CSEnterCriticalSection.
	self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveExitCriticalSection [
	"Exit the critical section.
	 This may change the active process as a result."
	| criticalSection owningProcessIndex inInterpreter owningProcess |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	(self isEmptyList: criticalSection)
		ifTrue:
			[objectMemory storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: objectMemory nilObject]
		ifFalse:
			["We're going to switch process, either to an interpreted frame or a machine
			  code frame. To know whether to return or enter machine code we have to
			  know from whence we came.  We could have come from the interpreter,
			  either directly or via a machine code primitive.  We could have come from
			  machine code.  The instructionPointer tells us where from:"
			 inInterpreter := instructionPointer >= objectMemory startOfMemory.
			 owningProcess := self removeFirstLinkOfList: criticalSection.
			 "store check unnecessary because aSemaphore referred to owningProcess
			  via its FirstLinkIndex slot before owningProcess was removed."
			 objectMemory storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: owningProcess.
			 "Note that resume: isn't fair; it won't suspend the active process.
			  For fairness we must do the equivalent of a primitiveYield, but that
			  may break old code, so we stick with unfair resume:."
			 (self resume: owningProcess
				preemptedYieldingIf: preemptionYields
				from: CSExitCriticalSection) ifTrue:
						[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]]
]

{ #category : #UI }
StackInterpreterMT >> primitiveGetNextEvent [
	self inGUIThread ifFalse: [ 
		^ self primitiveFailFor: PrimErrInappropriate ].
	^ super primitiveGetNextEvent
]

{ #category : #'process primitives' }
StackInterpreterMT >> primitiveProcessBindToThreadId [
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
		[1halt.^self primitiveFailFor: PrimErrBadArgument].
	id := id = objectMemory nilObject ifTrue: [0] ifFalse: [objectMemory integerValueOf: id].
	id >= cogThreadManager maxNumThreads ifTrue:
		[1halt.^self primitiveFailFor: PrimErrLimitExceeded].
	(ec := self bindProcess: aProcess toId: id) ~= 0 ifTrue:
		[1halt.^self primitiveFailFor: ec].
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
StackInterpreterMT >> primitiveProcessBoundThreadId [
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
StackInterpreterMT >> primitiveRelinquishProcessor [
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
		[self cCode:
			[self memcpy: savedReenterInterpreter asVoidPointer
				_: reenterInterpreter
				_: (self sizeof: #'jmp_buf')].
		 threadIndexAndFlags := self disownVM: DisownVMForProcessorRelinquish.
		 self assert: relinquishing.
		 self ioRelinquishProcessorForMicroseconds: (objectMemory integerValueOf: microSecs).
		 self assert: relinquishing.
		 self ownVM: threadIndexAndFlags.
		 self assert: relinquishing not.
		 self assert: cogThreadManager currentVMThread state = CTMAssignableOrInVM.
		 self cCode:
			[self assert: (self mem: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
						cm: reenterInterpreter
						p: (self sizeof: #'jmp_buf')) = 0]].
	self assert: (objectMemory fetchPointer: MyListIndex ofObject: self activeProcess) = objectMemory nilObject.
	self pop: 1  "microSecs; leave rcvr on stack"
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveResume [
	"Put this process on the scheduler's lists thus allowing it to proceed next time there is
	 a chance for processes of it's priority level.  It must go to the back of its run queue so
	 as not to preempt any already running processes at this level.  If the process's priority
	 is higher than the current process, preempt the current process."
	| proc inInterpreter |
	proc := self stackTop.  "rcvr"
	(objectMemory isContext: (objectMemory followField: SuspendedContextIndex ofObject: proc)) ifFalse:
		[^self primitiveFail].
	"We're about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	(self resume: proc preemptedYieldingIf: preemptionYields from: CSResume) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]

	"Personally I would like to check MyList, which should not be one of the elements of the scheduler lists.
	 But there are awful race conditions in things like should:notTakeMoreThan: that mean we can't.
	 eem 9/27/2010 23:08. e.g.

	| proc myList classLinkedList |
	proc := self stackTop.
	myList := objectMemory fetchPointer: MyListIndex ofObject: proc.
	classLinkedList := self superclassOf: (objectMemory splObj: ClassSemaphore).
	((self fetchClassOfNonInt: myList) ~= classLinkedList
	and: [objectMemory isContext: (objectMemory fetchPointer: SuspendedContextIndex ofObject: proc)]) ifFalse:
		[^self primitiveFail].
	''We're about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:''
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	(self resume: proc  preemptedYieldingIf: preemptionYields from: CSResume) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]"
]

{ #category : #UI }
StackInterpreterMT >> primitiveScreenSize [

	self inGUIThread ifFalse: [ 
		^ self primitiveFailFor: PrimErrInappropriate ].
	^ super primitiveScreenSize
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveSignal [
	"Synchronously signal the semaphore.
	 This may change the active process as a result."
	| inInterpreter |
	"We may be about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	(self synchronousSignal: self stackTop) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveSuspend [
	"Primitive. Suspend the receiver, aProcess such that it can be executed again
	by sending #resume. If the given process is not currently running, take it off
	its corresponding list. The primitive returns the list the receiver was previously on."
	| process myList |
	process := self stackTop.
	process = self activeProcess ifTrue:
		[| inInterpreter |
		"We're going to switch process, either to an interpreted frame or a machine
		 code frame. To know whether to return or enter machine code we have to
		 know from whence we came.  We could have come from the interpreter,
		 either directly or via a machine code primitive.  We could have come from
		 machine code.  The instructionPointer tells us where from:"
		self pop: 1 thenPush: objectMemory nilObject.
		inInterpreter := instructionPointer >= objectMemory startOfMemory.
		self transferTo: self wakeHighestPriority from: CSSuspend.
		^self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter].
	myList := objectMemory fetchPointer: MyListIndex ofObject: process.
	"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
	but we can't easily so just do a quick check for nil which is the most common case."
	myList = objectMemory nilObject ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	"Alas in Spur we need a read barrier"
	(objectMemory isForwarded: myList) ifTrue:
		[myList := objectMemory followForwarded: myList.
		 objectMemory storePointer: MyListIndex ofObject: process withValue: myList].
	self removeProcess: process fromList: myList.
	self successful ifTrue:
		[objectMemory storePointer: MyListIndex ofObject: process withValue: objectMemory nilObject.
		 self pop: 1 thenPush: myList]
]

{ #category : #'process primitives' }
StackInterpreterMT >> primitiveVMCurrentThreadId [
	<export: true>
	"Answer the VM's current thread's Id"
	self cCode: [] inSmalltalk: [cogThreadManager isNil ifTrue: [^self primitiveFail]].
	self pop: 1 thenPushInteger: cogThreadManager getVMOwner
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveWait [
	| sema excessSignals activeProc inInterpreter |
	sema := self stackTop.  "rcvr"
	excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: sema.
	excessSignals > 0
		ifTrue:
			[self storeInteger: ExcessSignalsIndex
				ofObject: sema
				withValue: excessSignals - 1]
		ifFalse:
			["We're going to switch process, either to an interpreted frame or a machine
			  code frame. To know whether to return or enter machine code we have to
			  know from whence we came.  We could have come from the interpreter,
			  either directly or via a machine code primitive.  We could have come from
			  machine code.  The instructionPointer tells us where from:"
			inInterpreter := instructionPointer >= objectMemory startOfMemory.
			activeProc := self activeProcess.
			self addLastLink: activeProc toList: sema.
			self transferTo: self wakeHighestPriority from: CSWait.
			self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> primitiveYield [
"primitively do the equivalent of Process>yield"
	| scheduler activeProc priority processLists processList inInterpreter |
	scheduler := self schedulerPointer.
	activeProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: scheduler.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: scheduler.
	processList := objectMemory fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifTrue:
		[^nil].
	"We're going to switch process, either to an interpreted frame or a machine
	 code frame. To know whether to return or enter machine code we have to
	 know from whence we came.  We could have come from the interpreter,
	 either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	self addLastLink: activeProc toList: processList.
	self transferTo: self wakeHighestPriority from: CSYield.
	self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter
]

{ #category : #'process primitive support' }
StackInterpreterMT >> recordContextSwitchFrom: aProcess in: sourceCode [
	"nothing"
]

{ #category : #'debug support' }
StackInterpreterMT >> recordThreadSwitchTo: ownerIndex source: sourceCode [
]

{ #category : #'process primitive support' }
StackInterpreterMT >> resume: aProcess preemptedYieldingIf: yieldImplicitly from: sourceCode [
	"Make aProcess runnable and if its priority is higher than  that of the
	 current process, preempt the current process.   Answer if the current
	 process was preempted.  If the current process was preempted then if
	 yieldImplicitly add the current process to the back of its run queue,
	 causing an implicit yeild to other processes on the run queue,  otherwise
	 add the current process to the front of its run queue, hence not yielding.
	 Blue book behaviour is to yield implicitly but is arguably incorrect.
	 Override to add tracing info."
	| activeProc activePriority newPriority |
	<inline: false>
	activeProc := self activeProcess.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority <= activePriority ifTrue:
		[self putToSleep: aProcess yieldingIf: true.
		 ^false].
	self putToSleep: activeProc yieldingIf: yieldImplicitly.
	self transferTo: aProcess from: sourceCode.
	^true
]

{ #category : #'process primitive support' }
StackInterpreterMT >> returnToExecutive: inInterpreter postContextSwitch: switchedContext [
	"Return to the current frame, either by entering machine code, or longjmp-ing back to the
	 interpreter or simply returning, depending on where we are. To know whether to return or
	 enter machine code we have to know from whence we came.  We could have come from
	 the interpreter, either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from.  If it is above startOfMemory we're
	 in the interpreter.  If it is below, then we are in machine-code unless it is ceReturnToInterpreterPC,
	 in which case we're in a machine-code primitive called from the interpreter."
	<inline: false>
	| fullyInInterpreter |
	<var: #cogMethod type: #'CogBlockMethod *'>

	self setMethod: (self iframeMethod: framePointer).
	fullyInInterpreter := inInterpreter.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	fullyInInterpreter ifFalse:
		[self siglong: reenterInterpreter jmp: ReturnToInterpreter.
		 "NOTREACHED"].
	^nil
]

{ #category : #'process primitive support' }
StackInterpreterMT >> returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: source [
	| savedReenterInterpreter |
	<var: #savedReenterInterpreter type: #'jmp_buf'>
	<var: #vmThread type: #'CogVMThread *'>
	<inline: false>
	"We must use a copy of reenterInterpreter since we're giving up the VM to another vmThread."
	self cCode:
			[self memcpy: savedReenterInterpreter asVoidPointer
				_: reenterInterpreter
				_: (self sizeof: #'jmp_buf')]
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
StackInterpreterMT >> sendInvokeCallbackContext: vmCallbackContext [
	"Override to add sanity assertions."
	self assertSaneThreadAndProcess.
	^super sendInvokeCallbackContext: vmCallbackContext
]

{ #category : #'internal interpreter access' }
StackInterpreterMT >> setCogVMFlags: flags [
	"Set an array of flags indicating various properties of the Cog VM.
	 Bit 0: if set, implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: if set, implies a threaded VM will not dosown the VM if owned by the GUI thread
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued
	 Bit 5: if set, implies wheel events will be delivered as such and not mapped to arrow key events"
	flags asUnsignedInteger > 63 ifTrue:
		[^self primitiveFailFor: PrimErrUnsupported].
	processHasThreadId := flags anyMask: 1.
	preemptionYields := flags noMask: 4.
	noThreadingOfGUIThread := flags anyMask: 8.
	newFinalization := flags anyMask: 16.
	sendWheelEvents := flags anyMask: 32
]

{ #category : #'image save/restore' }
StackInterpreterMT >> setImageHeaderFlagsFrom: headerFlags [
	"Set the flags that are contained in the 7th long of the image header."
	imageHeaderFlags := headerFlags. "so as to preserve unrecognised flags."
	fullScreenFlag := headerFlags bitAnd: 1.
	imageFloatsBigEndian := (headerFlags noMask: 2) ifTrue: [1] ifFalse: [0].
	processHasThreadId := headerFlags anyMask: 4.
	preemptionYields := headerFlags noMask: 16.
	noThreadingOfGUIThread := headerFlags anyMask: 32.
	newFinalization := headerFlags anyMask: 64.
	sendWheelEvents := headerFlags anyMask: 128.

	processHasThreadId ifFalse:
		[self print: 'warning, processHasThreadId flag is unset; cannot function as a threaded VM if so.'; cr]
]

{ #category : #'process primitive support' }
StackInterpreterMT >> setMaxWaitingPriorityTo: minPriority [
	maxWaitingPriority := minPriority
]

{ #category : #'process primitive support' }
StackInterpreterMT >> setOwnerIndexOfProcess: aProcess to: anIndex bind: bind [
	| threadId |
	threadId := anIndex = 0
				ifTrue: [objectMemory nilObject]
				ifFalse: [objectMemory integerObjectOf: (anIndex << 1) + (bind ifTrue: [1] ifFalse: [0])].
	objectMemory storePointerUnchecked: ThreadIdIndex ofObject: aProcess withValue: threadId
]

{ #category : #'process primitive support' }
StackInterpreterMT >> synchronousSignal: aSemaphore [ 
	"Signal the given semaphore from within the interpreter.
	 Answer if the current process was preempted.
	 Override to add tracing info."
	| excessSignals |
	<inline: false>
	(self isEmptyList: aSemaphore) ifTrue:
		["no process is waiting on this semaphore"
		 excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: aSemaphore.
		 self storeInteger: ExcessSignalsIndex
			ofObject: aSemaphore
			withValue: excessSignals + 1.
		 ^false].

	objectMemory ensureSemaphoreUnforwardedThroughContext: aSemaphore.

	^self resume: (self removeFirstLinkOfList: aSemaphore)
		preemptedYieldingIf: preemptionYields
		from: CSSignal
]

{ #category : #'process primitive support' }
StackInterpreterMT >> threadIdFieldOf: aProcess [
	^processHasThreadId
		ifTrue: [objectMemory fetchPointer: ThreadIdIndex ofObject: aProcess]
		ifFalse: [objectMemory nilObject]
]

{ #category : #accessing }
StackInterpreterMT >> threadManager [
	<doNotGenerate>
	^cogThreadManager
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> threadManager: aThreadManager [
	<doNotGenerate>
	cogThreadManager := aThreadManager
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> threadSchedulingLoop: vmThread [
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
StackInterpreterMT >> threadSwitchIfNecessary: newProc from: sourceCode [
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

{ #category : #'vm scheduling' }
StackInterpreterMT >> transferTo: aProcess [

	self error: 'should use #transferTo:from:'
]

{ #category : #'process primitive support' }
StackInterpreterMT >> transferTo: newProc from: sourceCode [
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
		 vmThread := cogThreadManager willingVMThread.
		 self returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: sourceCode.
		 self error: 'scheduler could not find a runnable process'].

	objectMemory storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	objectMemory storePointerUnchecked: MyListIndex ofObject: newProc withValue: objectMemory nilObject.

	self threadSwitchIfNecessary: newProc from: sourceCode.

	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc
]

{ #category : #'cog jit support' }
StackInterpreterMT >> tryLockVMOwner [
	<api>
	^ self
		cCode: '!pthread_mutex_trylock(&vmOwnerLock)'
		inSmalltalk: [ true "taken" ]
]

{ #category : #'vm scheduling' }
StackInterpreterMT >> tryToExecuteSmalltalk: vmThread [
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
StackInterpreterMT >> unlockVMOwner [
	<api>
	^ self
		cCode: 'pthread_mutex_unlock(&vmOwnerLock)'
		inSmalltalk: [ self "unlock does never fail" ]
]

{ #category : #'frame access' }
StackInterpreterMT >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"Update the frame's spouse context with the frame's current state except for the
	 sender and instruction pointer, which are used to mark the context as married."
	| theContext tempIndex pointer argsPointer |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #pointer type: #'char *'>
	<var: #argsPointer type: #'char *'>
	self assert: (self frameHasContext: theFP).
	theContext := self frameContext: theFP.
	self assert: (objectMemory isContext: theContext).
	self assert: (self frameReceiver: theFP)
				= (objectMemory noFixupFollowField: ReceiverIndex ofObject: theContext).
	tempIndex := self frameNumArgs: theFP.
	 pointer := theFP + FoxReceiver - objectMemory wordSize.

	"update the arguments. this would appear not to be strictly necessary, but is for two reasons.
	 First, the fact that arguments are read-only is only as convention in the Smalltalk compiler;
	 other languages may choose to modify arguments.
	 Second, the Squeak runUntilErrorOrReturnFrom: nightmare pops the stack top, which may, in
	 certain circumstances, be the last argument, and hence the last argument may not have been
	 stored into the context."
	argsPointer := theFP + (self frameStackedReceiverOffsetNumArgs: tempIndex).
	1 to: tempIndex do:
		[:i|
		argsPointer := argsPointer - objectMemory wordSize.
		self assert: (objectMemory addressCouldBeOop: (stackPages longAt: argsPointer)).
		 objectMemory storePointer: ReceiverIndex + i
			ofObject: theContext
			withValue: (stackPages longAt: argsPointer)].
	"now update the non-argument stack contents."
	[pointer >= theSP] whileTrue:
		[self assert: (objectMemory addressCouldBeOop: (stackPages longAt: pointer)).
		 tempIndex := tempIndex + 1.
		 objectMemory storePointer: ReceiverIndex + tempIndex
			ofObject: theContext
			withValue: (stackPages longAt: pointer).
		 pointer := pointer - objectMemory wordSize].
	self assert: ReceiverIndex + tempIndex < (objectMemory lengthOf: theContext).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (objectMemory integerObjectOf: tempIndex)
]

{ #category : #'cog jit support' }
StackInterpreterMT >> vmOwnerLockAddress [
	<api> "NB. For the JIT only, so it can generate the lock & unlock functions."
	<returnTypeC: #usqInt>
	^processHasThreadId
		ifTrue: [self cCode: '(usqInt)&GIV(vmOwnerLock)'
					inSmalltalk: [self inMemoryVMOwnerLockAddress]]
		ifFalse: [0]
]

{ #category : #'process primitive support' }
StackInterpreterMT >> waitingPriorityIsAtLeast: minPriority [
	"Set the maxWaitingPriority to at least minPriority on behalf
	 of a thread wanting to acquire the VM.  If maxWaitingPriority
	 is increased, schedule a thread activation check asap."
	maxWaitingPriority < minPriority ifTrue:
		[maxWaitingPriority := minPriority.
		 checkThreadActivation := true.
		 self forceInterruptCheck]
]

{ #category : #'process primitive support' }
StackInterpreterMT >> wakeHighestPriority [
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
	self externalWriteBackHeadFramePointers.
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
			  self cppIf: SPURVM ifTrue: 
				["This is uncommon, so we can deal with forwarders here instead of assuming there isn't."
				 (self isOopForwarded: ctxt) ifTrue:
					[ctxt := self fixFollowedField: SuspendedContextIndex ofObject: proc withInitialValue: ctxt].
				  (self isLiveContext: ctxt) ifTrue:
					[highestRunnableProcessPriority := p + 1.
					^proc].].
			 self warning: 'evicted zombie process from run queue']].
	^nil
]
