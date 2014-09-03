Class {
	#name : #SMarkWeakScalingRunnerExecutor,
	#superclass : #Object,
	#instVars : [
		'numInnerIterations',
		'benchmarkSelector',
		'suite',
		'runner'
	],
	#category : #'CogBenchmarks-SMark'
}

{ #category : #'as yet unclassified' }
SMarkWeakScalingRunnerExecutor class >> createFor: aSelector for: numIterations with: aRunner and: aSuite [
	| o |
	o := self new.
	o runner: aRunner.
	o suite: aSuite.
	o innerIterations: numIterations.
	o benchmarkSelector: aSelector.
	^ ([ o run ] newProcess)
]

{ #category : #accessing }
SMarkWeakScalingRunnerExecutor >> benchmarkSelector: aSelector [
	benchmarkSelector := aSelector
]

{ #category : #accessing }
SMarkWeakScalingRunnerExecutor >> innerIterations: anInt [
	numInnerIterations := anInt
]

{ #category : #benchmarking }
SMarkWeakScalingRunnerExecutor >> run [
	1 to: numInnerIterations do: [:i |
		suite perform: benchmarkSelector.].
	
	runner executorCompleted.
]

{ #category : #accessing }
SMarkWeakScalingRunnerExecutor >> runner: aRunner [
	runner := aRunner
]

{ #category : #accessing }
SMarkWeakScalingRunnerExecutor >> suite: aSuite [
	suite := aSuite
]
