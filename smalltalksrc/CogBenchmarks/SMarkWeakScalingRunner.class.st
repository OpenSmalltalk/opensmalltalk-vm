Class {
	#name : #SMarkWeakScalingRunner,
	#superclass : #SMarkRunner,
	#instVars : [
		'numInnerIterations',
		'runningProcesses',
		'completionSignal',
		'runningProcessesMtx'
	],
	#category : #'CogBenchmarks-SMark'
}

{ #category : #defaults }
SMarkWeakScalingRunner class >> defaultNumberOfInnerIterations [
	"The number of iterations of the inner loop
	 in which the benchmark is executed."
	^ 1
]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> execute: aSelector withProcesses: numberOfProcesses withTimer: timer [
	"This case is meant for all cases. REM: this is also used for numProc==1 to be able to measure the process start overhead in all cases.
	 It will start the processes and wait for their completion."
	
	| processes |
	processes			:= Array new: numberOfProcesses.
	runningProcessesMtx := Semaphore forMutualExclusion.
	completionSignal		:= Semaphore new.
	runningProcesses := numberOfProcesses.
	
	"First initialize the processes"
	1 to: numberOfProcesses do: [ :procNum |
		| proc |
		proc := SMarkWeakScalingRunnerExecutor createFor: aSelector for: numInnerIterations with: self and: suite.
		proc priority: Processor highestPriority.
		proc name: (self class name, '-',  procNum asString).
		processes at: procNum put: proc.
		"On: procNum"
	].
	
	"Now, execute the benchmark and do the timing now"
	timer start.
	1 to: numberOfProcesses do: [ :procNum |
		(processes at: procNum) resume.
	].
	completionSignal wait.
	timer stop.
	
]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> executorCompleted [
	runningProcessesMtx critical: [
		runningProcesses := runningProcesses - 1.
		(runningProcesses == 0) ifTrue: [
			completionSignal signal.
		]
	]
]

{ #category : #initialization }
SMarkWeakScalingRunner >> initialize [
	super initialize.
	numProcesses			:= self class defaultNumberOfProcesses.
	numInnerIterations	:= self class defaultNumberOfInnerIterations.

]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> innerIterations [
	"The number of inner iterations the benchmark is executed inside a processes"
	^ numInnerIterations
]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> innerIterations: anInteger [
	"The number of inner iterations the benchmark is executed inside a processes"
	numInnerIterations := anInteger
]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> processes [
	^ numProcesses
]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> processes: anInteger [
	numProcesses := anInteger
]

{ #category : #reporting }
SMarkWeakScalingRunner >> reportConfiguration: aStream [
	super reportConfiguration: aStream.
	aStream << ('inner iterations: ', numInnerIterations asString); cr.
]

{ #category : #benchmarking }
SMarkWeakScalingRunner >> timedBenchmarkExecution: aSelector [
	"Will do a timed execution of the benchmark and return the result timer"
	| timer |
	timers := Dictionary new.

	timer := self createTimer: 'total'.
	
	self execute: aSelector withProcesses: numProcesses withTimer: timer.
	
	self recordResults: timer for: aSelector.
	
	^ timer
]
