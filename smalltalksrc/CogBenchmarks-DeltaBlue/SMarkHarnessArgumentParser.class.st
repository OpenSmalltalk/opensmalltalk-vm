Class {
	#name : #SMarkHarnessArgumentParser,
	#superclass : #Object,
	#instVars : [
		'runner',
		'reporter',
		'suiteOrBenchmark',
		'iterations',
		'processes',
		'problemSize',
		'i',
		'current',
		'numParams',
		'currentObj',
		'arguments',
		'suite',
		'specificBenchmark',
		'suiteClass',
		'harness'
	],
	#category : #'CogBenchmarks-SMark'
}

{ #category : #'argument parsing' }
SMarkHarnessArgumentParser >> determineBenchmarkParameters [
	"Initialize with defaults, will be overwritten in case
	 it is specified."
	iterations := runner class defaultNumberOfIterations.
	processes  := runner class defaultNumberOfProcesses.
	problemSize:= suiteClass defaultProblemSize.
	
	self determineBenchmarkParametersFromArguments.
]

{ #category : #'argument parsing' }
SMarkHarnessArgumentParser >> determineBenchmarkParametersFromArguments [
	i := i + 1.
	i <= numParams ifTrue: [
		iterations := (arguments at: i) asInteger.
		i := i + 1.
		i <= numParams ifTrue: [
			processes := (arguments at: i) asInteger.
			i := i + 1.
			i <= numParams ifTrue: [
				problemSize := arguments at: i.
			]
		]
	].
]

{ #category : #'argument parsing' }
SMarkHarnessArgumentParser >> determineReporter [
	(currentObj isKindOf: SMarkReporter)
		ifFalse: [ reporter := harness defaultReporter new. ]
		ifTrue:  [ reporter := currentObj.
			i := i + 1.
			i <= numParams ifTrue: [
				current := arguments at: i.
			]
		].
]

{ #category : #'argument parsing' }
SMarkHarnessArgumentParser >> determineRunner [
	(currentObj isKindOf: SMarkRunner)
		ifFalse: [ runner := harness defaultRunner new. ]
		ifTrue:  [ runner := currentObj.
			i := i + 1.
			i <= numParams ifTrue: [
				current := arguments at: i.
				currentObj := (Smalltalk classNamed: current) ifNotNilDo: [:cls | cls new].
			]
		].
]

{ #category : #'argument parsing' }
SMarkHarnessArgumentParser >> determineSuiteOrBenchmark [
	self parseBenchmarkOrSuite: current.
]

{ #category : #accessing }
SMarkHarnessArgumentParser >> harness: aHarness [
	harness := aHarness
]

{ #category : #helper }
SMarkHarnessArgumentParser >> instructRunner [
	suite := suiteClass new.
	specificBenchmark ifNotNil: [
		suite runOnly: specificBenchmark.
	].
	
	runner suite: suite.
 	runner iterations: iterations.
	runner processes: processes.
	runner problemSize: problemSize.
]

{ #category : #parsing }
SMarkHarnessArgumentParser >> parse: argumentsArray [
	arguments := argumentsArray.
	numParams := arguments size.
	
	i := 2.
	current := arguments at: i.
	currentObj := (Smalltalk classNamed: current) ifNotNilDo: [:cls | cls new].
		
	self determineRunner.
	self determineReporter.
	
	self determineSuiteOrBenchmark.
	
	self determineBenchmarkParameters.
	
	self instructRunner.
	
	^ {runner. reporter}
]

{ #category : #'argument parsing' }
SMarkHarnessArgumentParser >> parseBenchmarkOrSuite: aBenchmarkOrSuite [
	"Identify the benchmark suite or suite and benchmark method
	 that should be executed. The string should be of the format 'Class>>benchName' or 'Class.benchName' for shell/bash compatibility.
	 Accepts a string, class, or array.
	 Returns, a class, or an array of a class and a symbol."
	| parsed |
	(aBenchmarkOrSuite isKindOf: Class)
		ifTrue: [
			suiteClass := aBenchmarkOrSuite.
			^ suiteClass
		].
	  
	(aBenchmarkOrSuite isKindOf: Array)
		ifTrue:  [ parsed := aBenchmarkOrSuite. ]
		ifFalse: [ parsed := aBenchmarkOrSuite findTokens: '>.'. ].
	
	((parsed size > 2) or: [parsed size < 1])
				ifTrue: [ Error signal: 'The passed argument has to represent two elements. A class/classname and a method symbol' ].
	
	suiteClass := parsed first.
	
	(suiteClass isKindOf: Class) 
		ifFalse: [ suiteClass := Smalltalk at: (suiteClass asSymbol) ifAbsent: [Error signal: 'Class that was supposed to represent a benchmark suite was not found: ', suiteClass asString ]].
	
	parsed size = 1
		ifTrue: [^suiteClass].

	specificBenchmark := parsed second asSymbol.
	
	^ { suiteClass. specificBenchmark }

]
