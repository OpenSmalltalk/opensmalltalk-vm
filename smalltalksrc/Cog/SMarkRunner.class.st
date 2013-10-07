Class {
	#name : #SMarkRunner,
	#superclass : #Object,
	#instVars : [
		'numIterations',
		'suite',
		'runner',
		'results',
		'currentBenchmark',
		'timers',
		'problemSize',
		'numProcesses'
	],
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #defaults }
SMarkRunner class >> defaultNumberOfIterations [
	^ 1
]

{ #category : #defaults }
SMarkRunner class >> defaultNumberOfProcesses [
	^ 1
]

{ #category : #defaults }
SMarkRunner class >> defaultTimer [
	^ SMarkTimer
]

{ #category : #benchmarking }
SMarkRunner class >> execute: aSuite [
	^ self execute: aSuite with: 1.
]

{ #category : #benchmarking }
SMarkRunner class >> execute: aSuite with: nIterations [
	| runner |
	runner := self new.
	aSuite runner: runner.
	runner suite: aSuite.
	runner iterations: nIterations.  
	runner execute.
	^ runner
]

{ #category : #helper }
SMarkRunner >> createTimer: name [
	"Create and register a new timer for the current benchmark"
	| timer |
	timer := self class defaultTimer new: name.
	
	timers ifNotNil: [
		timers at: name put: timer.
	].
	
	^ timer.
]

{ #category : #execution }
SMarkRunner >> execute [
	suite run.
	self runBaseBenchmark.
	^ results
	
]

{ #category : #initialization }
SMarkRunner >> initialize [
	super initialize.
	numIterations := self class defaultNumberOfIterations.
	numProcesses  := self class defaultNumberOfProcesses.
	results := Dictionary new.
]

{ #category : #accessing }
SMarkRunner >> iterations [
	^ numIterations
]

{ #category : #accessing }
SMarkRunner >> iterations: anInteger [
	numIterations := anInteger
]

{ #category : #benchmarking }
SMarkRunner >> performBenchmark: aSelector [
	currentBenchmark := aSelector.
	
	1 to: numIterations do: [:i|
		"self timedBenchmarkExecution: aSelector."
		suite runBenchmark: aSelector.  
	].	
	
	currentBenchmark := nil.
	
	^ results at: (suite benchmarkNameForSelector: aSelector)
]

{ #category : #printing }
SMarkRunner >> printOn: aStream [
	^ self reportOn: aStream.
]

{ #category : #accessing }
SMarkRunner >> problemSize [
	<omniUnenforced> "Hint for the OMOP that it is part of the meta infrastructure"
	^ problemSize
]

{ #category : #accessing }
SMarkRunner >> problemSize: aValue [
	"Do some conversion to make it easier for the benchmarks"
	(aValue isString and: [aValue isAllDigits]) ifTrue: [
		problemSize := Number readFrom: aValue.
		^ self.
	].

	problemSize := aValue
]

{ #category : #accessing }
SMarkRunner >> processes [
	"The standard runner does use only a single process, but in case a benchmark supports parallelism it can query for the intended degree of parallelism"
	^ numProcesses
]

{ #category : #accessing }
SMarkRunner >> processes: anInt [
	"The standard runner does use only a single process, but a benchmark can use that to do its own parallelism"
	numProcesses := anInt
]

{ #category : #helper }
SMarkRunner >> recordResults: timer for: aSelector [
	| result name |
	name := suite benchmarkNameForSelector: aSelector.
	
	result := SMarkResult new.
	result total: timer totalTime.
	result benchmarkName: name.
	result suite: suite.
	result criteria: timers.
	
	(results at: name ifAbsentPut: OrderedCollection new) add: result.
]

{ #category : #accessing }
SMarkRunner >> report [
	SMarkReporter defaultReporter reportFor: self.  
	
]

{ #category : #reporting }
SMarkRunner >> reportConfiguration: aStream [
	aStream << 'Runner Configuration:';cr.
	aStream << ('  iterations: ', numIterations asString); cr.
	aStream << ('  processes: ', numProcesses asString); cr.
	aStream << ('  problem size: ', problemSize asString); cr.

]

{ #category : #reporting }
SMarkRunner >> reportOn: aStream [
	SMarkReporter defaultReporter reportFor: self on: aStream  
	
]

{ #category : #accessing }
SMarkRunner >> results [
	^ results
]

{ #category : #benchmarking }
SMarkRunner >> runBaseBenchmark [
	"In certain sitatuations it is one wants a baseline that is incooprated in all 
	 benchmark results to be substracted from the final values.
	
	#baseBenchmark can be used to charaterize such a baseline"
	
	(suite respondsTo: #baseBenchmark) 
		ifFalse: [ ^ nil ].
	
	^ self performBenchmark: #baseBenchmark.
]

{ #category : #accessing }
SMarkRunner >> suite [
	^ suite
]

{ #category : #accessing }
SMarkRunner >> suite: aBenchmarkSuite [
	suite := aBenchmarkSuite.
	suite runner: self.
]

{ #category : #benchmarking }
SMarkRunner >> timedBenchmarkExecution: aSelector [
	"Will do a timed execution of the benchmark and return the result timer"
	| timer result |
	timers := Dictionary new.

	timer := self createTimer: 'total'.
	
	timer start.
	result := suite perform: aSelector.
	timer stop.
	suite processResult: result withTimer: timer.
	
	self recordResults: timer for: aSelector.
	
	^ timer
]
