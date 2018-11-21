"
A benchmark harness steers the execution and reporting of benchmarks.
For that purpose, it will use a designated benchmark runner to do the execution and a benchmark reporter to output the results.
The benchmark harness is also parameterized by the benchmark suites that are to be executed.

The simplest way to execute a benchmark suite is to use SMarkSuite >> #run.

However, directly using the harness classes gives more freedom on reporting and execution strategies.

A typical call of the harness from the commandline would result in the following invokation:
	SMarkHarness run: {'SMarkHarness'. 'SMarkLoops.benchIntLoop'. 1. 1. 5}
"
Class {
	#name : #SMarkHarness,
	#superclass : #Object,
	#category : #'CogBenchmarks-SMark'
}

{ #category : #helper }
SMarkHarness class >> defaultArgumentParser [
	^ SMarkHarnessArgumentParser
]

{ #category : #defaults }
SMarkHarness class >> defaultOutputDestination [
	^ Smalltalk at:       #ScriptConsole
	            ifAbsent: [SMarkReporter defaultOutputDestination]
]

{ #category : #defaults }
SMarkHarness class >> defaultReporter [
	^ SMarkReporter defaultReporter
]

{ #category : #defaults }
SMarkHarness class >> defaultRunner [
	^ SMarkSuite defaultRunner
]

{ #category : #benchmarking }
SMarkHarness class >> execute: runner andReport: reporter [
	runner reportConfiguration: self defaultOutputDestination.
	runner execute.
	reporter runner: runner.
	reporter outputStream: self defaultOutputDestination.
	reporter report.
]

{ #category : #benchmarking }
SMarkHarness class >> execute: aBenchmarkOrSuite using: aRunnerClass andReport: withAReporterClass [
	| parsedBenchmarkOrSuite runner reporter |
	
	parsedBenchmarkOrSuite := self parseBenchmarkOrSuite: aBenchmarkOrSuite.
	
	runner := aRunnerClass new.
	reporter := withAReporterClass new.
	self instructRunner: runner with: parsedBenchmarkOrSuite.
	self execute: runner andReport: reporter.   
]

{ #category : #helper }
SMarkHarness class >> parseArguments: arguments [
	| parser |
	parser := self defaultArgumentParser new.
	parser harness: self.
	^ parser parse: arguments.
]

{ #category : #'script entry' }
SMarkHarness class >> run: arguments [
	"Executed from the command line using something similar to
	 ./vm my.image SMarkHarness SMarkRunner SMarkReporter SMarkLoops\>\>benchIntLoop 1 1 5
	 ./vm my.image SMarkHarness SMarkRunner SMarkReporter SMarkLoops.benchIntLoop 1 1 5"

	| runner reporter runnerAndReporter |
	
	(self shouldShowUsage: arguments)
		ifTrue: [
			self usage.
			^ self.
		].
	
	runnerAndReporter := self parseArguments: arguments.
	runner := runnerAndReporter first.
	reporter := runnerAndReporter second.  
	
	self execute: runner andReport: reporter. 
]

{ #category : #helper }
SMarkHarness class >> shouldShowUsage: arguments [
	
	arguments size < 2 ifTrue: [^ true ].
	
	^ arguments anySatisfy: [:elem | (elem = '--help') or: [elem = '-?'] ].  
]

{ #category : #helper }
SMarkHarness class >> usage [
	| usage |
	"Example usage: SMarkHarness SMarkRunner SMarkReporter SMarkLoops.benchIntLoop 1 1 5"
	
	usage := self usageHeader.
	
	usage := usage, 'Arguments:', String crlf.
	usage := self usageRunner:   usage.
	usage := self usageReporter: usage.
	usage := usage, ' suiteOrBenchmark   required, either a SMarkSuite with benchmarks,', String crlf.
	usage := usage, '                              or a benchmark denoted by Suite.benchName', String crlf.
	usage := self usageBenchmarkParameters: usage.
	
	self defaultOutputDestination print: usage.
]

{ #category : #helper }
SMarkHarness class >> usageBenchmarkParameters: usage [
	^ usage,	' iterations         optional, number of times the benchmarks are repeated', String crlf,
				' processes          optional, number of processes/threads used by the benchmarks', String crlf,
				' problemSize        optional, depending on benchmark for instance number of', String crlf,
				'                              inner iterations or size of used data set', String crlf.

]

{ #category : #helper }
SMarkHarness class >> usageHeader [
	| usage |
	usage := 'SMark Benchmark Framework, version: ', self version, String crlf.
	usage := usage, String crlf.
	usage := usage, 'Usage: <vm+image> ', self name, ' [runner] [reporter] <suiteOrBenchmark>', String crlf.
	usage := usage, '                               [iterations [processes [problemSize]]]', String crlf.
	usage := usage, String crlf.
	^ usage
]

{ #category : #helper }
SMarkHarness class >> usageReporter: usage [
	^ usage,	' reporter           optional, a SMarkReporter class that processes', String crlf,
				'                              and displays the results', String crlf.
	
]

{ #category : #helper }
SMarkHarness class >> usageRunner: usage [
	^ usage, ' runner             optional, a SMarkRunner class that executes the benchmarks', String crlf.
]

{ #category : #helper }
SMarkHarness class >> version [
	(Smalltalk classNamed: #ConfigurationOfBenchmarking)
		ifNotNilDo: [:cfg |
			^ cfg project currentVersion versionNumber asString.
		].
	  
	(Smalltalk classNamed: #MCPackage)
		ifNotNilDo: [:mcp |
			| package |
			package := mcp named: 'SMark'.
			package hasWorkingCopy ifTrue: [
				^ package workingCopy ancestors first name.
			].
		].
	
	^ ''.
]
