"
Richards is an OS kernel simulation benchmark, originally written in BCPL by Martin Richards. The main focus in Richards is on property access and calling functions and methods.

To run the benchmark, execute the expression 'SMarkRichards run: 10'.
"
Class {
	#name : #SMarkRichards,
	#superclass : #SMarkSuite,
	#category : #'CogBenchmarks-Richards'
}

{ #category : #benchs }
SMarkRichards >> benchRichards [

	RichObject initialize.
	self problemSize timesRepeat: [ RichRunner start ]
]

{ #category : #benchs }
SMarkRichards >> defaultProblemSize [
	^ 50
]

{ #category : #benchs }
SMarkRichards >> problemSize [
	<omniUnenforced> "Hint for the OMOP that it is part of the meta infrastructure"
	| ps |
	ps := super problemSize.
	
	ps isInteger ifFalse: [	^ self defaultProblemSize].
		
	^ ps
]
