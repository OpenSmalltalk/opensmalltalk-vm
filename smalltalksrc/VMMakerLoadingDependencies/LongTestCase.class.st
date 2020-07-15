"
A LongTestCase is a TestCase that usually takes a long time to run. Because of this users can decide if they want to execute these or not, by changing the ""Run long test cases"" preference.
"
Class {
	#name : #LongTestCase,
	#superclass : #TestCase,
	#classVars : [
		'ShouldRun'
	],
	#category : #VMMakerLoadingDependencies
}

{ #category : #accessing }
LongTestCase class >> allTestSelectors [

	self shouldRun ifTrue: [
		^super testSelectors ].
	^#().
]

{ #category : #'instance creation' }
LongTestCase class >> buildSuite [

	self shouldRun ifTrue: [ ^super buildSuite ].
	^self suiteClass new
]

{ #category : #accessing }
LongTestCase class >> doNotRunLongTestCases [

	self shouldRun: false
]

{ #category : #testing }
LongTestCase class >> isAbstract [
	"Override to true if a TestCase subclass is Abstract and should not have
	TestCase instances built from it"

	^self name == #LongTestCase
			
]

{ #category : #accessing }
LongTestCase class >> runLongTestCases [

	self shouldRun: true
]

{ #category : #accessing }
LongTestCase class >> shouldRun [

	<preference: 'Run long test cases'
		category: 'SUnit'
		description: 'If true, the tests defined as taking a long time to run (those  in subclasses of LongTestCase) will run when they are selected in the Test Runner.'
		type: #Boolean>
	^ShouldRun ifNil: [ true ]
]

{ #category : #accessing }
LongTestCase class >> shouldRun: aBoolean [

	ShouldRun := aBoolean
]

{ #category : #'as yet unclassified' }
LongTestCase >> defaultTimeout [
	"Answer the default timeout to use for tests in this test case. The timeout is a value in seconds."

	^super defaultTimeout * 10
]
