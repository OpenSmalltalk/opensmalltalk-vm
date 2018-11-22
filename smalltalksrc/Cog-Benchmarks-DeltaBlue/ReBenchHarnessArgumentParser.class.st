Class {
	#name : #ReBenchHarnessArgumentParser,
	#superclass : #SMarkHarnessArgumentParser,
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #'argument parsing' }
ReBenchHarnessArgumentParser >> determineBenchmarkParametersFromArguments [
	i := i + 1.
	i <= numParams ifTrue: [
		processes := (arguments at: i) asInteger.
		i := i + 1.
		i <= numParams ifTrue: [
			iterations := (arguments at: i) asInteger.
			i := i + 1.
			i <= numParams ifTrue: [
				problemSize := arguments at: i.
			]
		]
	].
]

{ #category : #'argument parsing' }
ReBenchHarnessArgumentParser >> determineReporter [
	reporter := harness defaultReporter new.
]

{ #category : #'argument parsing' }
ReBenchHarnessArgumentParser >> determineRunner [
	runner := harness defaultRunner new.
]

{ #category : #helper }
ReBenchHarnessArgumentParser >> instructRunner [
	super instructRunner.
	
	runner iterations: runner class defaultNumberOfIterations.
	runner innerIterations: iterations.
]
