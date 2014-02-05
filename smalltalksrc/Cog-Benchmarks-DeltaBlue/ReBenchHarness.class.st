"
The ReBenchHarness is optimized for use from the command-line.
It is especially meant to be used together with ReBench, a tool to execute and document benchmarks reproducibly.

See: https://github.com/smarr/ReBench#readme
"
Class {
	#name : #ReBenchHarness,
	#superclass : #SMarkHarness,
	#category : #'Cog-Benchmarks-SMark'
}

{ #category : #helper }
ReBenchHarness class >> defaultArgumentParser [
	^ ReBenchHarnessArgumentParser
]

{ #category : #defaults }
ReBenchHarness class >> defaultReporter [
	^ ReBenchReporter
]

{ #category : #defaults }
ReBenchHarness class >> defaultRunner [
	^ SMarkWeakScalingRunner
]

{ #category : #helper }
ReBenchHarness class >> usageBenchmarkParameters: usage [
	^ usage,		' processes          optional, number of processes/threads used by the benchmarks', String crlf,
				' inner-iterations   optional, number of iterations done by a single process', String crlf,
				' problemSize        optional, depending on benchmark for instance size of used data set', String crlf.
				
]

{ #category : #helper }
ReBenchHarness class >> usageHeader [
	| usage |
	usage := 'SMark Benchmark Framework, version: ', self version, String crlf.
	usage := usage, String crlf.
	usage := usage, 'Usage: <vm+image> ', self name,
				' <suiteOrBenchmark> [processes [inner-iterations [problemSize]]]', String crlf.
	usage := usage, String crlf.
	
	usage := usage, '  This harness is used for weak-scalling benchmarks.', String crlf.
	usage := usage, '  Use the SMarkHarness for more general settings, it offers more options.', String crlf.
	
	usage := usage, String crlf.
	^ usage
]

{ #category : #helper }
ReBenchHarness class >> usageReporter: usage [
	"Will rely on default, which is good for ReBench, so do not advertise option."
	^ usage
]

{ #category : #helper }
ReBenchHarness class >> usageRunner: usage [
	"Will rely on default, which is good for ReBench, so do not advertise option."
	^ usage
]
