"
A benchmark result is characterized by:
 - the total execution time (#total is the least a benchmark results in)
 - the name of the benchmark that was executed
 - the suite object specifies the used input used for the benchmark
 - dictionary of additional the criteria and the related timings

A benchmark can produced multiple resuts for different criteria. The standard criterion is #total.
"
Class {
	#name : #SMarkResult,
	#superclass : #Object,
	#instVars : [
		'time',
		'benchName',
		'suite',
		'criteria'
	],
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #accessing }
SMarkResult >> benchmarkName [
	^ benchName
]

{ #category : #accessing }
SMarkResult >> benchmarkName: aString [
	benchName := aString
]

{ #category : #accessing }
SMarkResult >> criteria [
	^ criteria
]

{ #category : #accessing }
SMarkResult >> criteria: aCollectionOfTimers [
	criteria := aCollectionOfTimers
]

{ #category : #accessing }
SMarkResult >> suite [
	^ suite
]

{ #category : #accessing }
SMarkResult >> suite: aBenchmarkSuite [
	suite := aBenchmarkSuite
]

{ #category : #accessing }
SMarkResult >> total [
	^ time
]

{ #category : #accessing }
SMarkResult >> total: aTime [
	time := aTime
]
