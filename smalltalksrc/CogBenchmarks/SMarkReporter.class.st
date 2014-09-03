"
SMarkReporter is a simple formatter of benchmark results. 

Subclass such as SMarkSimpleStatisticsReporter might implement more advanced reporting functionality, e.g., including a statistical evaluation of the results.

Example:

	| f |
	f := TextStream on: String new.
	SMarkSimpleStatisticsReporter reportFor: (SMarkTestRunnerSuiteForAutosizing run: 10) on: f.
	f contents
"
Class {
	#name : #SMarkReporter,
	#superclass : #Object,
	#instVars : [
		'runner',
		'stream'
	],
	#category : #'CogBenchmarks-SMark'
}

{ #category : #defaults }
SMarkReporter class >> defaultOutputDestination [
	^ ScriptConsole
]

{ #category : #defaults }
SMarkReporter class >> defaultReporter [
	^ SMarkSimpleStatisticsReporter
]

{ #category : #reporting }
SMarkReporter class >> reportFor: aRunner [
	self reportFor: aRunner on: self defaultOutputDestination.
]

{ #category : #reporting }
SMarkReporter class >> reportFor: aRunner on: aStream [
	| reporter |
	reporter := self new.
	reporter runner: aRunner.
	reporter outputStream: aStream.
	reporter report.
	^ reporter.
]

{ #category : #reporting }
SMarkReporter >> benchmarkFooter: aName [
	stream cr.
]

{ #category : #reporting }
SMarkReporter >> benchmarkHeader: aName [
	stream << 'Benchmark ' << (aName asString); cr.
]

{ #category : #reporting }
SMarkReporter >> footer [
	"No output at the moment"
	^ self
]

{ #category : #reporting }
SMarkReporter >> header [
	| suiteName |
	suiteName := runner suite class name asString.
	stream << 'Report for: ' << suiteName; cr.
]

{ #category : #initialization }
SMarkReporter >> initialize [
	super initialize.
	stream := self class defaultOutputDestination.
]

{ #category : #accessing }
SMarkReporter >> outputStream: aStream [
	stream := aStream  
]

{ #category : #accessing }
SMarkReporter >> report [
	self header.
	
	runner results keysAndValuesDo: [:key :value |
		self benchmarkHeader: key.
		self reportAllRuns: value of: key.
		self benchmarkFooter: key.
	].

	self footer.
	^ self
]

{ #category : #reporting }
SMarkReporter >> reportAllRuns: aListOfResults of: benchmark [
	aListOfResults do: [:result |
		result criteria keysAndValuesDo: [:benchName :timer |
			stream << benchName << ': ' << (timer totalTime asString, 'ms'); cr.]]
]

{ #category : #accessing }
SMarkReporter >> runner: aRunner [
	runner := aRunner.
]
