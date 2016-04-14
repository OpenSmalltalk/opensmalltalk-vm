"
Instances of this class represent control blocks for native threads that cooperatively schedule the VM.  See the class comment of CogThreadManager for full documentation.

N.B. awolProcesses must be the last inst var.
"
Class {
	#name : #CogVMThread,
	#superclass : #VMStructType,
	#instVars : [
		'index',
		'state',
		'priority',
		'osSemaphore',
		'osThread',
		'newMethodOrNull',
		'argumentCount',
		'inMachineCode',
		'cStackPointer',
		'cFramePointer',
		'reenterInterpreter',
		'awolProcIndex',
		'awolProcLength',
		'awolProcesses'
	],
	#pools : [
		'VMThreadingConstants'
	],
	#category : #'VMMaker-Multithreading'
}

{ #category : #simulation }
CogVMThread class >> alignedByteSize [
	"this is a simulation only hack"
	^self instSize * 4
]

{ #category : #translation }
CogVMThread class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogVMThread struct."

	self allInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['awolProcesses']			-> [{#sqInt. '[', CogThreadManager awolProcessesIncrement printString, ']'}].
						['cStackPointer']			-> [#'void *'].
						['cFramePointer']		-> [#'void *'].
						['osSemaphore']			-> ['sqOSSemaphore'].
						['osThread']				-> ['sqOSThread'].
						['reenterInterpreter']	-> ['jmp_buf'] }
					otherwise:
						[#sqInt])]
]

{ #category : #documentation }
CogVMThread class >> notes [
	"win32: When a thread terminates, the thread object attains a signaled state, satisfying any threads that were waiting on the object.

	if (WaitForSingleObject( hThread, 0) == WAIT_OBJECT_0) {
		// the thread handle is signaled - the thread has terminated
	}
	else {
		// the thread handle is not signaled - the thread is still alive
	}

	Alternatively use BOOL WINAPI GetExitCodeThread(HANDLE hThread, LPDWORD lpExitCode)
	which returns STILL_ACTIVE if still active.

	DWORD retval;

	if (GetExitCodeThread( hThread, &retval) == STILL_ACTIVE) {
		// the thread is still alive
	}
	else {
		// the thread has terminated
	}

	pthreads:
		The pthread_kill() function sends a signal, specified by sig, to a
		thread, specified by thread.  If sig is 0, error checking is performed,
		but no signal is actually sent.

		pthread_kill() will fail if:
			[ESRCH]		thread is an invalid thread ID.

	if (pthread_kill(thread, 0) == ESRCH) {
		// the thread can't be found and has teminated
	}
	else {
		// the thread can be found and has either not terminated or the handle has been reused
	}"
]

{ #category : #accessing }
CogVMThread >> argumentCount [
	"Answer the value of argumentCount"

	^ argumentCount
]

{ #category : #accessing }
CogVMThread >> argumentCount: anObject [
	"Set the value of argumentCount"

	^argumentCount := anObject
]

{ #category : #accessing }
CogVMThread >> awolProcIndex [
	"Answer the value of awolProcIndex"

	^ awolProcIndex
]

{ #category : #accessing }
CogVMThread >> awolProcIndex: anObject [
	"Set the value of awolProcIndex"

	^awolProcIndex := anObject
]

{ #category : #accessing }
CogVMThread >> awolProcLength [
	"Answer the value of awolProcLength"

	^ awolProcLength
]

{ #category : #accessing }
CogVMThread >> awolProcLength: anObject [
	"Set the value of awolProcLength"

	^awolProcLength := anObject
]

{ #category : #accessing }
CogVMThread >> awolProcesses [
	"Answer the value of awolProcesses"

	^ awolProcesses
]

{ #category : #accessing }
CogVMThread >> awolProcesses: anObject [
	"Set the value of awolProcesses"

	^awolProcesses := anObject
]

{ #category : #accessing }
CogVMThread >> cFramePointer [
	"Answer the value of cFramePointer"

	^ cFramePointer
]

{ #category : #accessing }
CogVMThread >> cFramePointer: anObject [
	"Set the value of cFramePointer"

	^cFramePointer := anObject
]

{ #category : #accessing }
CogVMThread >> cStackPointer [
	"Answer the value of cStackPointer"

	^ cStackPointer
]

{ #category : #accessing }
CogVMThread >> cStackPointer: anObject [
	"Set the value of cStackPointer"

	^cStackPointer := anObject
]

{ #category : #'simulation only' }
CogVMThread >> growAWOLProcesses [
	<doNotGenerate>
	awolProcesses setObject: awolProcesses object, (Array new: CogThreadManager awolProcessesIncrement)
]

{ #category : #accessing }
CogVMThread >> inMachineCode [
	"Answer the value of inMachineCode"

	^ inMachineCode
]

{ #category : #accessing }
CogVMThread >> inMachineCode: anObject [
	"Set the value of inMachineCode"

	^inMachineCode := anObject
]

{ #category : #accessing }
CogVMThread >> index [
	"Answer the value of index"

	^ index
]

{ #category : #accessing }
CogVMThread >> index: anObject [
	"Set the value of index"

	^index := anObject
]

{ #category : #'initialize-release' }
CogVMThread >> initialize [
	<doNotGenerate>
	awolProcLength := CogThreadManager awolProcessesIncrement.
	awolProcesses := CArrayAccessor on: (Array new: awolProcLength).
	awolProcIndex := 0
]

{ #category : #accessing }
CogVMThread >> newMethodOrNull [
	"Answer the value of newMethodOrNull"

	^ newMethodOrNull
]

{ #category : #accessing }
CogVMThread >> newMethodOrNull: anObject [
	"Set the value of newMethodOrNull"

	^newMethodOrNull := anObject
]

{ #category : #accessing }
CogVMThread >> osSemaphore [
	"Answer the value of osSemaphore"

	^ osSemaphore
]

{ #category : #accessing }
CogVMThread >> osSemaphore: anObject [
	"Set the value of osSemaphore"

	^osSemaphore := anObject
]

{ #category : #accessing }
CogVMThread >> osThread [
	"Answer the value of osThread"

	^ osThread
]

{ #category : #accessing }
CogVMThread >> osThread: anObject [
	"Set the value of osThread"

	^osThread := anObject
]

{ #category : #accessing }
CogVMThread >> priority [
	"Answer the value of priority"

	^ priority
]

{ #category : #accessing }
CogVMThread >> priority: anObject [
	"Set the value of priority"

	^priority := anObject
]

{ #category : #accessing }
CogVMThread >> reenterInterpreter [
	"Answer the value of reenterInterpreter"

	^ reenterInterpreter
]

{ #category : #accessing }
CogVMThread >> reenterInterpreter: anObject [
	"Set the value of reenterInterpreter"

	^reenterInterpreter := anObject
]

{ #category : #accessing }
CogVMThread >> state [
	"Answer the value of state"

	^ state
]

{ #category : #accessing }
CogVMThread >> state: anObject [
	"Set the value of state"

	^state := anObject
]
