"
This runner profiles the benchmarks for better analysis. Unlike the classical benchmark runner this one will not collect the results. Instead it will execute the benchmarks in the system profiler.
"
Class {
	#name : #SMarkProfileRunner,
	#superclass : #SMarkRunner,
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #profiling }
SMarkProfileRunner class >> execute: aSuite selector: aBenchmarkSelector [
	| runner |
	runner := self new.
	aSuite runner: runner.
	runner 
		suite: aSuite;
		execute: aBenchmarkSelector.
	^ runner
]

{ #category : #profiling }
SMarkProfileRunner class >> execute: aSuite selector: aBenchmarkSelector iterations: nIterations [
	| runner |
	runner := self new.
	aSuite runner: runner.
	runner 
		suite: aSuite;
		iterations: nIterations;
		execute: aBenchmarkSelector.
	^ runner
]

{ #category : #profiling }
SMarkProfileRunner >> execute [
	"run all benchmnarks in a benchmark suite "
	[ suite run ] timeProfile
]

{ #category : #profiling }
SMarkProfileRunner >> execute: aSelector [
	
	[ self performBenchmark: aSelector ] timeProfile
]

{ #category : #initialization }
SMarkProfileRunner >> initialize [
	super initialize.
	numIterations := 1.
]

{ #category : #benchmarks }
SMarkProfileRunner >> performBenchmark: aSelector [
	currentBenchmark := aSelector.
	
	1 to: numIterations do: [:i|
		suite runBenchmark: aSelector ].	
	
	currentBenchmark := nil.
]

{ #category : #benchmarks }
SMarkProfileRunner >> timedBenchmarkExecution: aSelector [
	suite perform: aSelector
]
