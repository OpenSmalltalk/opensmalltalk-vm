Class {
	#name : #SMarkAutosizeRunner,
	#superclass : #SMarkRunner,
	#instVars : [
		'targetTime',
		'innerLoopIterations'
	],
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #defaults }
SMarkAutosizeRunner class >> defaultTargetTime [
	"300 milliseconds seems to be a reasonable target time for most problems.
	 It is a compromise between the general measurment noise as well as timer accuracy
	 and the absolute runtime of benchmarks"
	^ 300
]

{ #category : #initialization }
SMarkAutosizeRunner >> initialize [
	super initialize.
	targetTime := self class defaultTargetTime.
]

{ #category : #benchmarking }
SMarkAutosizeRunner >> performBenchmark: aSelector [
	"First determine a useful number of inner loop iterations until the targetTime is reached."
	| execTime i |
	"make sure no timers are recorded for this"
	timers := nil.
	
	i := 1.
	execTime := Time millisecondsToRun: [ suite perform: aSelector. ].
	
	[ execTime > targetTime ] whileFalse: [
		i := i * 2. "Was thinking of doing something fancy here, but just go with this simple staight-forward solution"
		execTime := Time millisecondsToRun: [ 1 to: i do: [:ignored| suite perform: aSelector]].
	].

	innerLoopIterations := i.
	
	"Then start executing the benchmark"
	^ super performBenchmark: aSelector.
]

{ #category : #benchmarking }
SMarkAutosizeRunner >> runBaseBenchmark [
	"baseBenchmark is not supported with autosizing. I do not see how that can be made possible since all different benchmarks will have different number of iterations, and the only way how a consistent baseline could be found would be to normalize the results, but well, incooprorating the baseline measurement with the statistical evaluation is harder than just substracting a one time value..., I am not going to do that here for the moment. Stefan 2011-03-20"
	
	(suite respondsTo: #baseBenchmark) 
		ifFalse: [ ^ nil ].
	
	"I decided to go here with a silent solution to avoid thinking about logging frameworks and Transcript to console convertion..."
	self recordResults: (self class defaultTimer new: 'total') for: #baseBenchmark  
]

{ #category : #accessing }
SMarkAutosizeRunner >> targetTime [
	"Target time in milliseconds"
	^ targetTime
]

{ #category : #accessing }
SMarkAutosizeRunner >> targetTime: anIntInMilliseconds [
	"Target time in milliseconds"
	targetTime := anIntInMilliseconds
]

{ #category : #benchmarking }
SMarkAutosizeRunner >> timedBenchmarkExecution: aSelector [
	"Will do a timed execution of the benchmark and return the result timer"
	| timer |
	timers := Dictionary new.

	timer := self createTimer: 'total'.
	
	timer start.
	1 to: innerLoopIterations do: [:ignored|
		suite perform: aSelector.
	].
	timer stop.
	
	self recordResults: timer for: aSelector.
	
	^ timer
]
