"
A ReBenchReporter is reporter for the ReBench framework (cf. https://github.com/smarr/ReBench).
It is used be the ReBenchHarness, which is the main class of interest for users that just want to execute benchmarks.
"
Class {
	#name : #ReBenchReporter,
	#superclass : #SMarkSimpleStatisticsReporter,
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #'as yet unclassified' }
ReBenchReporter >> benchmarkHeader: aName [
	^ self
]
