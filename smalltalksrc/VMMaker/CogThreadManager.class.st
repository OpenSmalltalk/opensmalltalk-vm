"
The sole instance of this class manages native threads that cooperatively schedule the VM.  Although there may be any number of threads attempting to use the VM there is only one thread that is actually running VM code at any one time.  That thread owns the VM and other threads queue to acquire the VM so that they may execute VM code.  Each thread that can own and run the VM has a ""vmThread"" thread control block which contains the necessary state to orchestrate this shared execution.

Acquiring ownership

VM ownership is indicated by a single variable ""vmOwner"" holding the index of the thread that currently owns the thread, or 0 if the VM is unowned.  The owning thread may disown the VM at any time by setting vmOwner to zero, but running threads must contend to acquire the vmOwner by setting vmOwner to their thread index.  vmOwnerLock is an atomic lock, probably implemented by CompareAndSwap or a similar low-level mutex.  To set vmOwner a thread must first lock vmOwnerLock and is then free to set vmOwner to its index if vmOwner is zero.

Ensuring Threads Exist

The VM has a heartbeat thread that is used for a number of things including periodically interrupting the VM to check for I/O, expired timers and so on.  This heartbeat thread is also essental to this threading system, where it is used as a watchdog.  When it wakes up it checks vmOwner and if zero then it either wakes up a thread in the queue, or if the queue is empty, spawns a new thread.  This thread will contend to become vmOwner, queueing itself if it fails.

Fast Call-out and Return

External calls can be made very quickly and simply using the watchdog to ensure that eventually there will be another thread to run the VM if a blocking call is made.  Immediately before the owning thread calls-out it remembers its index, which by definition is the value of vmOwner, in a local variable and sets vmOwner to zero.  If the call continues for long enough the watchdog will notice vmOwner is zero and wake up a thread to run the VM.  When the calling thread returns it attempts to reacquire the VM, using vmOwnerLock.  When it acquires vmOwnerLock it tests vmOwner and if zero simply reassigns its index to vmOwner and releases vmOwnerLock.  If vmOwner is non-zero then the thread adds itself to the queue of waiting threads, and will complete the call when the VM next becomess available.  To make a call-out that prevents other threads from running until after it returns the call-out machinery simply neglects to clear vmOwner.  A bit in the ExternalFunction's flags instance variable enables threading, set if the FFI pragma begins with the keyword threaded, e.g. <cdecl: threaded char* 'ffiPrintString' (char *)>.

If not already ""bound"", a call-out binds a Process to the thread making a call-out on its behalf for the dynamic extent of the call.  This means that subsequent call-outs from the process that are nested within the dynamc extent of the outer call occur on the same thread.  See the section below on Thread/Process Affinity and Binding.  Note that the process cannot be bound to a different thread.  If it were it would be running on that thread.  A thread may run any unbound process, but a bound process can only run on the thread to which it is bound.

A bound process that is having a call-out evaluated on its behalf is no longer strictly runnable.  The thread is running an external call but the process cannot be scheduled until the call-out has returned or called-back, and therefore it must not be left on the runnable process queues.  But if it is removed from the runnable process queues it must have a strong reference from somewhere otherwise it will be garbage collected.  Hence for the duration of the call-out->call-back or call-out->return execution during which the thread is execution externally a process is referenced strongly from the awolProcesses stack of the vmThread. And to be identifieable as running external code the process will have its myList field set to the ProcessInExternalCodeTag (a LinkedList), but for simplicity won't actually be on the list to avoid having the VM know how to remove a process from an arbitrary position in the list.  The awolProcesses set is a stack to allow a thread to make nested callouts on behalf of any number of unbound threads.

Call-back

A call-back must do two things; first it must acquire ownership, temporarily setting vmOwner to some illegal non-zero value such as -1, and then it must then search for its index.  Since it may be a thread as-yet unknown to the threading system it may not find its index and must allocate and initialize a vmThread and assign an index for itself.  Finally it can set vmOwner to its actual thread index, and proceed with the call-back.  The call-back machinery must note the state of vmOwner on entry and restore it on return to C to keep vmOwner consistent with its value at the start of a call-out.

Thread/Process Affinity and Binding

There must be some correspondence between Smalltalk processes and threads.  Some APIs, in particular the OpenGL and Windows debug APIs, require that all calls to the API are made from a single thread.  Any call into Smalltalk can reasonably expect to be called-back on the same thread.  The system therefore allows Smalltalk processes to be bound to specific threads and if a process is unbound when it makes a call-out, binds that Process to the thread making a call-out on its behalf for the dynamic extent of the call.  The system maintains a many-to-one mapping of processes to threads. A process indicates the thread to which it is bound using the fourth slot of Process which is threadId.

One can control the binding of processes to threads in advance of a call-out using thread affinity.  An affinity is simply the binding of a process to a specific thread that is created before any call-out and that will not be undone when any call-out returns.

A Cog VM flag (the least significant bit of Smalltalk vmParameterAt: 48) records whether the current image's Process class defines the fourth slot.  If the bit is not set the thread system is inoperative.  If set, the VM knows it can use the fourth slot of a Process for the process's threadId.  If a Process's threadId is nil then any thread can execute that process.  If the threadId is an integer then its least significant bit is zero for a temporary binding but 1 for a permanent affinity, and the value shifted down 1 position to remove the lsb is the threadId of the thread to which it is bound or affined.

Scheduling

In effect a bound thread is free to run an unbound or unaffined process until it attempts a call-out.  An unbound thread is free to run any unbound process, but a bound or affined process can only run on the thread to which it is bound or affined.  A primitive is provided to set or clear (but not change) a Process's affinity.  We use a primitive because it can be atomic [Open to question: , and can maintain the invariant that a bound process is in the boundProcesses set of its thread].

When the current thread makes a process switch to another Smalltalk process it checks the threadId of the highest-priority runnable process.  If the threadId is nil or matches the current thread then that thread continues, running the process.  If not, it attempts to wake the process's thread and adds itself to the queue of waiting threads.  If the thread is already executing external code then the VM blocks; i.e. the VM will not preempt a runnable process because that process is bound to an unavailable thread.

To avoid the situation where the thread to be awoken is unavailable because it is running on behalf of some other thread, when the current thread considers making a process switch to another Smalltalk process and that process is bound, the thread first checks if it is bound to the current process and if so simply disowns the VM and adds itself to the queue of waiting threads.  The watchdog will notice the VM is unowned and make sure some other thread is available to run the VM.  The watchdog therefore has to ensure that there exists at least one unbound thread in the queue.

Implementation

The effect of vmLock is to ensure that the only manipulation of the core thread data structures, the set of vmThreads et al, is made by the thread that owns the VM.  In particular the watchdog temporarily locks the VM before waking a thread on the queue and so no thread touches the queue unless it owns the VM.  Since the core data structures are only manipulated by the owning thread their use is entirely lock-free (apart from vmLock itself) and we can simply use a realloc(3)'ed array of pointers to vmThreads, which in the simulator are instances of CogVMThread and in the actual VM CogVMThread structs derived there-from.  We use an array of pointers so that realloc'ing the array doesn't affect individual vmThread structs, reducing the need for locking.  This also allows us to represent the awolProcesses stack as slots on the end of a CogVMThread struct, reallocing the struct as necessary when pushing processes on the stack.

To save time locating the vmThread for a thread the VM stores a thread's index in thread-local storage.  However, vmLock holds the index of the owning thread, so the thread-local storage mechanism need be used only for other than the owning thread.

vmOwnerLock is locked and unlocked in a processor-specific manner.  The Cogit generates two functions ceTryLockVMOwner and ceUnlockVMOwner that lock and unlock vmOwnerLock using processor-specific mechanisms, which on x86 is the XCHG locked-swap instruction.

There are abstractions for the OS threading system defined in platforms/<plat>/vm/sqPlatformSpecific.h and a small API of helper functions defined in platforms/Cross/vm/sq.h to insulate the VM from platform specifics.  Look for the COGMTVM define.

sqOSThread is the type of the platform's thread handle, e.g. pthread_t on pthreads and HANDLE on win32.
sqOSSemaphore is the type of the platform's queueing semaphore upon which a thread can wait, used to implement threads waiting in the queue.

void ioInitThreadLocalThreadIndices(void)
	initializes the thread-local storage mechanism, enabling the following two functions.
void ioSetThreadLocalThreadIndex(long)
	sets the calling thread's index to the argument.
long ioGetThreadLocalThreadIndex(void)
	answers the calling thread's index, answering zero in a thread that has not yet set its index.

int ioNewOSThread(void (*startFunction)(int), int)
	spawns a new thread that starts by evaluating func with the supplied argument (which
	will be its thread index).  Answers 0 on success and an error code on failure.
void ioExitOSThread(sqOSThread thread)
	terminates the thread argument and releases any resources associated with it maintained by this subsystem.
void ioReleaseOSThreadState(sqOSThread thread)
	releases any resources associated with the thread maintained by this subsystem.
int ioNewOSSemaphore(sqOSSemaphore *)
	Assigns through the argument a new OS semaphore on which a sqOSThread
	may wait.  Answers 0 on success and an error code on failure.  The semaphore
	functions take pointers because in e.g. the pthreads implementation an OSSemaphore
	is a structure, not a pointer, and teh structure cannot be copied and still function correctly.
void ioSignalOSSemaphore(sqOSSemaphore *)
	signals the argument's referent, allowing the thread waiting on it to proceed.
void ioWaitOnOSSemaphore(sqOSSemaphore *)
	blocks the calling thread until the argument's referent is signalled.
sqOSThread ioCurrentOSThread(void)
	answers the current thread.
int ioOSThreadsEqual(sqOSThread,sqOSThread)
	answers non-zero if the two arguments are the same thread.
int ioOSThreadIsAlive(sqOSThread)
	answers non-zero if the argument is still running (has not crashed or terminated).


The above API is used to implement the following functions used by the VM to share itself amongst threads.

void startThreadSubsystem(void)
	initializes the threading subsystem, aborting if there is an error.
sqInt disownVM(void)
	disownVM clears vmOwner, answering its previous value which is the index of the disowning thread, marked with a flag indicating if the activeProcess was newly affined to the thread in disownVM.  Sets the activeProcess's affinity and sets its list to the ProcessInExternalCodeTag.  Pushes the activeProcess on the vmThread's awolProcesses stack.
void ownVM(sqInt)
	ownVM gains ownership of the VM, blocking until possible.  The argument is the index of the owning thread, or zero if not known, combined with the newly-affined flag.  Pops the activeProcess from the vmThread's awolProcesses stack, clears its thread affinity if appropriate, and puts the old activeProcess to sleep.

To initialize a thread, foreign or otherwise, to use the VM the thread must first evaluate
	startVMThread(CogVMThread *)
This will either be evaluated as the startFunction of ioNewOSThread or by a thread making a callback that finds it is unknown to the VM (its ioGetThreadLocalThreadIndex() is zero).


Simulation only variables:
	coInterpreter		CoInterpreterMT
	cogit				the jit
	threadLocalStorage	Dictionary of Process -> Array
	processorOwner		Process
Implemetation variables:
	vmOwner			Integer the index of the owning VM thread.  If 0, the VM is unowned
	vmOwnerLock		Integer the low-level lock protecting vmOwner
	threads				Array of pointer to CogVMThread the set of thread control blocks
	numThreads			size of threads
	numThreadsIncrement	increment by which to increase threads
	memoryIsScarce		boolean
	vmOSThread		sqOSThread the OS thread that most recently owned the VM.  This is for signalSemaphoreWithIndex
"
Class {
	#name : #CogThreadManager,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'cogit',
		'threadLocalStorage',
		'processorOwner',
		'vmOwner',
		'vmOwnerLock',
		'threads',
		'numThreads',
		'numThreadsIncrement',
		'memoryIsScarce',
		'vmOSThread'
	],
	#pools : [
		'VMThreadingConstants'
	],
	#category : #'VMMaker-Multithreading'
}

{ #category : #accessing }
CogThreadManager class >> awolProcessesIncrement [
	^AWOLProcessesIncrement
]

{ #category : #translation }
CogThreadManager class >> declareCVarsIn: cCodeGen [
	cCodeGen
		removeVariable: 'coInterpreter';
		removeVariable: 'cogit';
		removeVariable: 'threadLocalStorage';
		removeVariable: 'processorOwner'.
	cCodeGen
		var: #threads type: #'CogVMThread **';
		var: #vmOSThread type: #sqOSThread
]

{ #category : #'class initialization' }
CogThreadManager class >> initialize [
	"CogThreadManager initialize"
	CTMInitializing := 1.
	CTMUnavailable := 2.	"off doing its own thing and not available to run the VM, e.g. calling-out."
	CTMAssignableOrInVM := 3.	"either owning the VM or blocked on its osSemaphore available for VM work"
	CTMWantingOwnership := 4.	"with something specific to do in the VM (e.g. return a result from a call-out, make a call-back)"

	"Define the size of the stack of processes at time of disown/own."
	AWOLProcessesIncrement := 4
]

{ #category : #'public api' }
CogThreadManager >> acquireVMFor: threadIndex [
	"Attempt to acquire the VM, eventually blocking until it becomes available.
	 Spin until the maxWaitingPriority has been updated if it is lower than this thread's priority."
	<returnTypeC: #'CogVMThread *'>
	| vmThread |
	<var: #vmThread type: #'CogVMThread *'>
	self assert: threadIndex = self ioGetThreadLocalThreadIndex.
	vmThread := self vmThreadAt: threadIndex.
	self assert: (vmThread state = CTMUnavailable
				or: [vmThread state = CTMWantingOwnership]).
	(self tryLockVMToIndex: threadIndex) ifFalse:
		[vmThread state: CTMWantingOwnership.
		 [self tryLockVMToIndex: threadIndex] whileFalse:
			[[coInterpreter getMaxWaitingPriority < vmThread priority] whileTrue:
				[cogit tryLockVMOwner ifTrue:
					[coInterpreter waitingPriorityIsAtLeast: vmThread priority.
					 cogit unlockVMOwner]].
			vmOwner ~= threadIndex ifTrue:
				[self ioWaitOnOSSemaphore: (self addressOf: vmThread osSemaphore)]]].
	vmOSThread := vmThread osThread.
	vmThread state: CTMAssignableOrInVM.
	^vmThread
]

{ #category : #simulation }
CogThreadManager >> assertProcessor: aProcessorAlien isInThread: aProcess [
	<doNotGenerate>
	self assert: processorOwner == aProcess
]

{ #category : #'public api' }
CogThreadManager >> currentVMThread [
	<returnTypeC: #'CogVMThread *'>
	^self vmThreadAt: self getVMOwner
]

{ #category : #'public api' }
CogThreadManager >> ensureRunningVMThread: vmIsRelinquishing [
	<returnTypeC: #void>
	| vmThread |
	<var: #vmThread type: #'CogVMThread *'>
	(self tryLockVMToIndex: -1) ifFalse:
		["self cCode: [coInterpreter print: 'ERVT failed to lock'; cr]." ^nil].
	(vmThread := self willingVMThread) ifNotNil:
		["If the VM is relinquishing the processor then only schedule a thread if it has work to do."
		 (vmIsRelinquishing
		  and: [vmThread state ~= CTMWantingOwnership]) ifTrue:
			[self releaseVM.
			 ^nil].
		 self setVMOwner: vmThread index.
		 vmOSThread := vmThread osThread.
		 self ioSignalOSSemaphore: (self addressOf: vmThread osSemaphore).
		 self ioTransferTimeslice.
		 "self cCode: [coInterpreter print: 'ERVT signalled '; printNum: vmThread index; cr]."
		 ^nil].

	"If the VM is relinquishing the processor then only schedule a thread if it has work to do."
	vmIsRelinquishing ifTrue:
		[self releaseVM.
		 ^nil].

	"If we have failed to allocate thread storage before there is no point continuing to
	 try to do so.  By this time we should have quite a few threads in the pool."
	(memoryIsScarce
	 or: [(vmThread := self unusedThreadInfo) isNil]) ifTrue:
		[self releaseVM.
		 "self cCode: [coInterpreter print: 'ERVT memory is scarce or no unused thread info or too many threads'; cr]."
		 ^nil].

	self setVMOwner: vmThread index.
	(self startThreadForThreadInfo: vmThread) ifFalse:
		[self releaseVM]
]

{ #category : #'public api' }
CogThreadManager >> getNumThreads [
	<cmacro: '() GIV(numThreads)'>
	^numThreads
]

{ #category : #'public api' }
CogThreadManager >> getVMOSThread [
	"This is for signalSemaphoreWithIndex in Cross/vm/sqExternalSemaphores.c"
	<api>
	<returnTypeC: #sqOSThread>
	^vmOSThread
]

{ #category : #'public api' }
CogThreadManager >> getVMOwner [
	self sqLowLevelMFence.
	^vmOwner
]

{ #category : #'thread set' }
CogThreadManager >> growThreadInfosToAtLeast: index [
	"Grow the thread infos to at least index in numThreadsIncrement quanta."
	| newThreads newNumThreads |
	<var: #newThreads type: #'CogVMThread **'>
	<inline: false>
	memoryIsScarce ifTrue:
		[^false].
	newNumThreads := index + numThreadsIncrement - 1 // numThreadsIncrement * numThreadsIncrement.
	newNumThreads >= self maxNumThreads ifTrue:
		[^false].
	"Since 0 is not a valid index we allocate one extra CogVMThread and use 1-relative indices."
	newThreads := self cCode: 'realloc(GIV(threads), (newNumThreads + 1) * sizeof(CogVMThread *))'
						inSmalltalk: [(Array new: newNumThreads)
										replaceFrom: 1 to: numThreads
										with: threads startingAt: 1].
	(newThreads notNil
	 and: [self populate: newThreads from: numThreads + 1 to: newNumThreads]) ifFalse:
		[self free: newThreads.
		 memoryIsScarce := true.
		 ^false].
	threads := newThreads.
	numThreads := newNumThreads.
	^true
]

{ #category : #simulation }
CogThreadManager >> guiProcess [
	"Simulation only; answer the simulator's first process."
	<doNotGenerate>
	^threads first osThread
]

{ #category : #'public api' }
CogThreadManager >> highestPriorityThreadIfHigherThan: activePriority expectedMax: maxPriority [
	"Answer the first vmThread waiting to acquire the VM that is of higher priority
	 than activePriority, or answer nil if none. If there is a higher priority thread
	 then set the coInterpreter's maxWaitingPriority to either the priority of the
	 next highest priority vmThread, or to 0 if none is waiting."
	<returnTypeC: #'CogVMThread *'>
	| vmThread highest nextHighest |
	<var: #vmThread type: #'CogVMThread *'>
	<var: #highest type: #'CogVMThread *'>
	<var: #nextHighest type: #'CogVMThread *'>
	highest := nextHighest := nil.
	"To make this fair we could remember the last index at which we
	 found the highest and start the search at the following index."
	1 to: numThreads do:
		[:i|
		vmThread := threads at: i.
		vmThread state = CTMWantingOwnership ifTrue:
			[self assert: vmThread priority <= maxPriority.
			 highest isNil
				ifTrue: [highest := vmThread]
				ifFalse:
					[vmThread priority > highest priority
						ifTrue:
							[nextHighest := highest.
							highest := vmThread]
						ifFalse:
							[nextHighest isNil
								ifTrue: [nextHighest := vmThread]
								ifFalse: [vmThread priority > nextHighest priority ifTrue:
											[nextHighest := vmThread]]]]]].
	highest isNil ifTrue: [^nil].

	highest priority <= activePriority ifTrue:
		[^nil].
	coInterpreter setMaxWaitingPriorityTo: (nextHighest isNil
											ifTrue: [0]
											ifFalse: [nextHighest priority]).
	^highest
]

{ #category : #'initialize-release' }
CogThreadManager >> initialize [
	<doNotGenerate>
	vmOwner := vmOwnerLock := numThreads := numThreadsIncrement := 0.
	memoryIsScarce := false.
	"N.B.  Do not initialize threadLocalStorage; leave this to ioInitThreadLocalThreadIndices"
]

{ #category : #simulation }
CogThreadManager >> ioCurrentOSThread [
	<doNotGenerate>
	"See platforms/<plat>/vm/sqPlatformSpecific.h for the real definition."
	^Processor activeProcess
]

{ #category : #simulation }
CogThreadManager >> ioDestroyOSSemaphore: semaphorePointer [ "<BlockClosure>" 
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	^self
]

{ #category : #simulation }
CogThreadManager >> ioExitOSThread: anOSThread [
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	anOSThread terminate.
	self ioReleaseOSThreadState: anOSThread
]

{ #category : #simulation }
CogThreadManager >> ioGetThreadLocalThreadIndex [
	<doNotGenerate>
	"Answer the thread index of the current thread/process or 0 if it is not yet defined.
	 See platforms/<plat>/vm/sqPlatformSpecific.h for the actual definition."
	^threadLocalStorage
		ifNil: [1] "pre initialization"
		ifNotNil: [threadLocalStorage at: Processor activeProcess]
]

{ #category : #simulation }
CogThreadManager >> ioMilliSleep: milliseconds [
	"Pause the calling thread/process for milliseconds.
	 See platforms/<plat>/vm/sqPlatformSpecific.h for the actual definition."
	<doNotGenerate>
	(Delay forMilliseconds: milliseconds) wait
]

{ #category : #simulation }
CogThreadManager >> ioNewOS: function Thread: vmThread [
	"Fork a new thread to evaluate function with the supplied argument.
	 Return 0 on success and non-zero on error.  The only errors equate
	 to running out of resources, ie. memory.
	 See platforms/Cross/vm/sq.h for the real definition."
	 
	<doNotGenerate>
	[self perform: function with: vmThread] fork.
	^0
]

{ #category : #simulation }
CogThreadManager >> ioNewOSSemaphore: semaphorePointer [ "<BlockClosure>" 
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	semaphorePointer value: Semaphore new.
	^0
]

{ #category : #simulation }
CogThreadManager >> ioNumProcessors [
	<doNotGenerate>
	"See platforms/<plat>/vm/sq<Plat>Threads.c for the real definition."
	^3 + 4 // 2
]

{ #category : #simulation }
CogThreadManager >> ioOSThreads: aThread Equal: bThread [
	<doNotGenerate>
	"See platforms/<plat>/vm/sqPlatformSpecific.h for the real definition."
	^aThread = bThread
]

{ #category : #simulation }
CogThreadManager >> ioReleaseThreadState: anOSThread [
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	threadLocalStorage removeKey: anOSThread ifAbsent: []
]

{ #category : #simulation }
CogThreadManager >> ioSetThreadLocalThreadIndex: index [
	<doNotGenerate>
	"See platforms/<plat>/vm/sqPlatformSpecific.h for the real definition."
	threadLocalStorage ifNil:
		[threadLocalStorage := WeakIdentityKeyDictionary new].
	threadLocalStorage at: Processor activeProcess put: index
]

{ #category : #simulation }
CogThreadManager >> ioSignalOSSemaphore: aSemaphorePtr [
	<var: #anOSSemaphore type: #'sqOSSemaphore *'>
	<returnTypeC: #void>
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	aSemaphorePtr value signal
]

{ #category : #simulation }
CogThreadManager >> ioTransferTimeslice [
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	Processor yield
]

{ #category : #simulation }
CogThreadManager >> ioWaitOnOSSemaphore: aSemaphorePtr [
	<var: #anOSSemaphore type: #'sqOSSemaphore *'>
	<returnTypeC: #void>
	<doNotGenerate>
	"See platforms/Cross/vm/sq.h for the real definition."
	"Simulate the VM's heartbeat by calling checkVMOwnershipFromHeartbeat
	 if the wait times-out."
	[aSemaphorePtr value waitTimeoutMSecs: 1000] whileTrue:
		[coInterpreter checkVMOwnershipFromHeartbeat]
]

{ #category : #simulation }
CogThreadManager >> maxNumThreads [
	^self cCode: [ThreadIdMask] inSmalltalk: [16]
]

{ #category : #'public api' }
CogThreadManager >> popAWOLProcess: vmThread [
	<var: #vmThread type: #'CogVMThread *'>
	self assert: vmThread awolProcIndex > 0.
	^vmThread awolProcesses at: (vmThread awolProcIndex: vmThread awolProcIndex - 1)
]

{ #category : #'thread set' }
CogThreadManager >> populate: vmThreadPointers from: start to: finish [
	"Populate vmThreadPointers with vmThreads over the given range."
	<var: #vmThreadPointers type: #'CogVMThread **'>
	| nThreads vmThreads |
	<var: #vmThreads type: #'CogVMThread *'>
	<var: #vmThread type: #'CogVMThread *'>
	<inline: true>
	nThreads := finish - start + 1.
	vmThreads := self cCode: [self c: nThreads alloc: (self sizeof: CogVMThread)]
						inSmalltalk: [CArrayAccessor on: ((1 to: nThreads) collect: [:ign| CogVMThread new])].
	vmThreads isNil ifTrue:
		[^false].
	self cCode:
			[start = 1 ifTrue:
				[vmThreadPointers at: 0 put: nil]]
		inSmalltalk: [].
	start to: finish do:
		[:i| | vmThread |
		vmThread := self addressOf: (vmThreads at: i - start).
		(self ioNewOSSemaphore: (self cCode: [self addressOf: vmThread osSemaphore]
										inSmalltalk: [[:sem| vmThread osSemaphore: sem]])) ~= 0 ifTrue:
			[start to: i - 1 do:
				[:j|
				vmThread := self addressOf: (vmThreads at: j - start).
				self ioDestroyOSSemaphore: (self addressOf: vmThread osSemaphore)].
			self free: vmThreads.
			^false].
		vmThreadPointers at: i put: vmThread.
		vmThread awolProcLength: AWOLProcessesIncrement.
		vmThread index: i].
	^true
]

{ #category : #'public api' }
CogThreadManager >> pushAWOLProcess: awolProcess on: vmThread [
	<var: #vmThread type: #'CogVMThread *'>
	<returnTypeC: #'CogVMThread *'>
	| cvt |
	<var: #cvt type: #'CogVMThread *'>
	cvt := vmThread.
	self assert: (cvt awolProcIndex between: 0 and: cvt awolProcLength).
	cvt awolProcIndex >= cvt awolProcLength ifTrue:
		["The realloc doesn't look like it grows but it does so by AWOLProcessesIncrement
		  entries because sizeof(CogVMThread) includes room for that many entries."
		 cvt := self cCode: 'realloc(cvt,sizeof(CogVMThread) + (sizeof(sqInt) * cvt->awolProcLength))'
					inSmalltalk: [cvt growAWOLProcesses].
		 threads at: vmThread index put: cvt.
		 cvt awolProcLength: cvt awolProcLength + AWOLProcessesIncrement].
	cvt awolProcesses at: cvt awolProcIndex put: awolProcess.
	cvt awolProcIndex: cvt awolProcIndex + 1.
	^cvt
]

{ #category : #scheduling }
CogThreadManager >> registerVMThread: vmThread [
	"Register the current thread in the set of threads, initializing the supplied
	 vmThread and setting the thread's thread block index there-to."
	<var: #vmThread type: #'CogVMThread *'>
	<returnTypeC: #'CogVMThread *'>
	self assert: (vmThread state = CTMInitializing
				or: [vmThread state = CTMWantingOwnership]).
	vmThread osThread: self ioCurrentOSThread.
	self ioSetThreadLocalThreadIndex: vmThread index.
	self assert: self ioGetThreadLocalThreadIndex = vmThread index.
	^vmThread
]

{ #category : #'public api' }
CogThreadManager >> releaseVM [
	self setVMOwner: 0
]

{ #category : #'initialize-release' }
CogThreadManager >> setInterpreter: aCoInterpreter cogit: aCogit [
	coInterpreter := aCoInterpreter.
	cogit := aCogit
]

{ #category : #'public api' }
CogThreadManager >> setVMOwner: index [
	<inline: false>
	self flag: #revisit.
	vmOwner := index.
	self sqLowLevelMFence
]

{ #category : #scheduling }
CogThreadManager >> startThreadForThreadIndex: index [
	index > numThreads ifTrue:
		[(self growThreadInfosToAtLeast: index) ifFalse:
			[^false]].
	^self startThreadForThreadInfo: (self vmThreadAt: index)
]

{ #category : #scheduling }
CogThreadManager >> startThreadForThreadInfo: vmThread [
	<var: #vmThread type: #'CogVMThread *'>
	<inline: false>
	self assert: vmThread state isNil.
	vmThread state: CTMInitializing.
	"self cCode: ''
		inSmalltalk: [coInterpreter transcript
						cr;
						nextPutAll: 'starting VM thread ';
						print: vmThread index;
						flush.
					 (thisContext home stackOfSize: 10) do:
						[:ctxt|
						coInterpreter transcript cr; print: ctxt; flush]]."
	(self ioNewOS: #startVMThread: Thread: vmThread) = 0 ifTrue:
		[self ioTransferTimeslice.
		^true].
	memoryIsScarce := true.
	"self cCode: [coInterpreter print: 'ERVT failed to spawn so memory is scarce'; cr]"
	^false
]

{ #category : #'public api' }
CogThreadManager >> startThreadSubsystem [
	"Initialize the threading subsystem, aborting if there is an error."
	| vmThread |
	<var: #vmThread type: #'CogVMThread *'>
	<inline: false>
	self assert: threads = nil.
	vmOSThread := self ioCurrentOSThread.
	numThreadsIncrement := (self ioNumProcessors max: 2) min: 16.
	(self growThreadInfosToAtLeast: numThreadsIncrement * 2) ifFalse:
		[self error: 'no memory to start thread system'].
	vmThread := threads at: 1.
	vmThread state: CTMInitializing.
	self registerVMThread: vmThread.
	vmThread state: CTMAssignableOrInVM.
	self setVMOwner: 1
]

{ #category : #scheduling }
CogThreadManager >> startVMThread: vmThread [
	"Start a VM thread that will attempt to acquire the VM and proceed
	 to run the VM, taking processes from the runnable process queue."
	<returnTypeC: #void>
	<var: #vmThread type: #'CogVMThread *'>
	self registerVMThread: vmThread.
	vmThread state: CTMAssignableOrInVM.
	coInterpreter threadSchedulingLoop: vmThread
]

{ #category : #locking }
CogThreadManager >> testVMOwnerIs: index [
	"Test what the vmOwner is from a process that may not be the current VM owner"
	| retryCount ownerIsIndex |
	self assert: index ~= 0.
	retryCount := 0.
	[cogit tryLockVMOwner] whileFalse:
		[(retryCount := retryCount + 1) > 10 ifTrue:
			[self ioTransferTimeslice]].
	ownerIsIndex := self getVMOwner = index.
	cogit unlockVMOwner.
	^ownerIsIndex
]

{ #category : #locking }
CogThreadManager >> tryLockVMToIndex: index [
	"Attempt to lock the vmOwner to index, answering if successful."
	| vmThread locked |
	<var: #vmThread type: #'CogVMThread *'>
	self assert: index ~= 0.
	cogit tryLockVMOwner ifFalse: [^false].
	self getVMOwner = 0 ifTrue:
		[self setVMOwner: index.
		 cogit unlockVMOwner.
		 index >= 1 ifTrue:
			[vmThread := self vmThreadAt: index.
			 vmOSThread := vmThread osThread.
			 self sqLowLevelMFence].
		 ^true].
	(locked := index > 0 and: [self getVMOwner = index]) ifTrue:
		[vmThread := self vmThreadAt: index.
		 vmOSThread := vmThread osThread.
		 self sqLowLevelMFence].
	cogit unlockVMOwner.
	^locked
]

{ #category : #scheduling }
CogThreadManager >> unregisterVMThread: vmThread [
	"Unegister the current thread in the set of threads."
	<var: #vmThread type: #'CogVMThread *'>
	self assert: (vmThread state ~= nil
				and: [vmThread state ~= CTMInitializing]).
	vmThread
		state: nil;
		osThread: nil.
	self ioSetThreadLocalThreadIndex: 0
]

{ #category : #'thread set' }
CogThreadManager >> unusedThreadInfo [
	"Answer a pointer to an unused CogVMThread, growing the sequence if necessary."
	<returnTypeC: #'CogVMThread *'>
	| vmThread index |
	<var: #vmThread type: #'CogVMThread *'>
	1 to: numThreads do:
		[:i|
		vmThread := threads at: i.
		self assert: vmThread index = i.
		vmThread state isNil ifTrue:
			[^vmThread]].
	index := numThreads + 1.
	(self growThreadInfosToAtLeast: numThreads + numThreadsIncrement) ifFalse:
		[^nil].
	^threads at: index
]

{ #category : #'public api' }
CogThreadManager >> vmThreadAt: index [
	<returnTypeC: #'CogVMThread *'>
	self assert: (index between: 1 and: numThreads).
	^threads at: index
]

{ #category : #'public api' }
CogThreadManager >> waitForWork: vmThread [
	"Wait for work."
	<var: #vmThread type: #'CogVMThread *'>
	<returnTypeC: #void>
	self assert: vmThread state = CTMAssignableOrInVM.
	self assert: vmOwner ~= vmThread index.
	self ioWaitOnOSSemaphore: (self addressOf: vmThread osSemaphore)
]

{ #category : #'public api' }
CogThreadManager >> wakeVMThreadFor: index [
	"Transfer the VM to the thread with index.  Called from a thread that finds the
	 highest priority runnable process is bound to the thread with index index."
	<returnTypeC: #void>
	| vmThread |
	<var: #vmThread type: #'CogVMThread *'>
	self assert: (vmOwner > 0 and: [vmOwner ~= index]).
	self assert: index <= numThreads.
	self setVMOwner: index.
	vmThread := threads at: index.
	vmThread state = nil
		ifTrue: [self startThreadForThreadInfo: vmThread]
		ifFalse:
			[self assert: vmThread state = CTMWantingOwnership.
			 self ioSignalOSSemaphore: (self addressOf: vmThread osSemaphore)].
	self ioTransferTimeslice
]

{ #category : #'thread set' }
CogThreadManager >> willingVMThread [
	"Answer a pointer to a live CogVMThread in any of the ``will do VM work''
	 states (other than the current owner if the VM is owned), or nil if none.
	 Preferentially answer threads wanting ownership."
	<returnTypeC: #'CogVMThread *'>
	| thread threadWantingVM threadWilling |
	<inline: false>
	<var: #thread type: #'CogVMThread *'>
	<var: #threadWantingVM type: #'CogVMThread *'>
	<var: #threadWilling type: #'CogVMThread *'>
	threadWantingVM := threadWilling := nil.
	1 to: numThreads do:
		[:i|
		 i ~= vmOwner ifTrue:
			[thread := threads at: i.
			 thread state =  CTMWantingOwnership ifTrue:
				[(threadWantingVM isNil
				  or: [threadWantingVM priority < thread priority]) ifTrue:
					[threadWantingVM := thread]].
			 thread state =  CTMAssignableOrInVM ifTrue:
				[(threadWilling isNil
				  or: [threadWilling priority < thread priority]) ifTrue:
					[threadWilling := thread]]]].
	threadWantingVM ifNotNil:
		[^threadWantingVM].
	threadWilling ifNotNil:
		[^threadWilling].
	^nil
]
