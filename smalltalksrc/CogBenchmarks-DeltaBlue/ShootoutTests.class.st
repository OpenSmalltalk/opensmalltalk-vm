Class {
	#name : #ShootoutTests,
	#superclass : #Object,
	#category : #'CogBenchmarks-Shootout'
}

{ #category : #platform }
ShootoutTests class >> arg [
	3 to: 5 do:
		[:i|
		(SmalltalkImage current getSystemAttribute: i) ifNotNil:
			[:aString|
			aString asInteger ifNotNil:
				[:arg| ^arg]]].
	^nil
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> binarytrees [
	self binarytrees: self arg to: self stdout.
	^''
]

{ #category : #benchmarking }
ShootoutTests class >> binarytrees: n to: output [
	| minDepth maxDepth stretchDepth check longLivedTree iterations |
	minDepth := 4.
	maxDepth := minDepth + 2 max: n.
	stretchDepth := maxDepth + 1.

	check := (ShootoutTreeNode bottomUpTree: 0 depth: stretchDepth) itemCheck.
	output
		nextPutAll: 'stretch tree of depth '; print: stretchDepth; tab;
		nextPutAll: ' check: '; print: check; nl.

	longLivedTree := ShootoutTreeNode bottomUpTree: 0 depth: maxDepth.
	minDepth to: maxDepth by: 2 do: [:depth|
		iterations := 1 bitShift: maxDepth - depth + minDepth.

		check := 0.
		1 to: iterations do: [:i|
			check := check + (ShootoutTreeNode bottomUpTree: i depth: depth) itemCheck.
			check := check + (ShootoutTreeNode bottomUpTree: -1*i depth: depth) itemCheck
			].
		output
			print:  (2*iterations); tab;
			nextPutAll: ' trees of depth '; print: depth; tab;
			nextPutAll: ' check: '; print: check; nl
		].

	output
		nextPutAll: 'long lived tree of depth '; print: maxDepth; tab;
		nextPutAll: ' check: '; print: longLivedTree itemCheck; nl
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> chameneosredux2 [
	self chameneosredux: self arg to: self stdout.
	^''
]

{ #category : #benchmarking }
ShootoutTests class >> chameneosredux: arg to: aStream [
   ShootoutMall runBenchMark: arg on: aStream
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> collectReferenceTimes [
	"Run the benchmarks 3 times and take their average, e.g. suitable
	 for filling in values for referenceTimesForClosureInterpreter"

	"ShootoutTests collectReferenceTimes"
	| n refs |
	Transcript clear.
	n := 3.
	refs := (1 to: n) collect: [:i| ShootoutTests runAllToInternalStream].
	^{	refs.
		(1 to: refs first size) collect:
			[:i|
			((refs inject: 0 into: [:sum :ref| (ref at: i) + sum]) / n) rounded] }
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> nbody [
	self nbody: self arg to: self stdout
]

{ #category : #benchmarking }
ShootoutTests class >> nbody: count to: output [
	| bodies |
	bodies := ShootoutNBodySystem new initialize.

	output print: bodies energy digits: 9; cr.
	count timesRepeat: [bodies after: 0.01].
	output print: bodies energy digits: 9; cr.
	^''
]

{ #category : #profiling }
ShootoutTests class >> profileAll [
	"self profileAll"
	| stream |
	stream := DummyStream new.
	self nbody: 200000 "20000000" to: stream.
	self binarytrees: 15 to: stream.
	self chameneosredux: 260000 to: stream.
	self threadring: 10000000 to: stream
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> referenceArgs [
	^self referenceTimesAndArgsForClosureInterpreter collect: [:ea| ea last]
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> referenceTimesAndArgsForClosureInterpreter [
	 "Interpreter + Closures VM (Mac Cocoa 5.7b3 27-Aug-10 >7BCAB029-A835-4D12-946D-4AB7083D2955< VMMaker versionString 4.4.9)
	  on Eliot's 2012 vintage 2.2GHz Intel (quad) Core i7 MacBook Pro"
	^Dictionary new
		at: #nbody				put: #(40903	2000000);
		at: #binarytrees		put: #(30573	17);
		at: #chameneosredux	put: #(30722	2000000);
		at: #threadring			put: #(9148		30000000);
		yourself
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> referenceTimesForClosureInterpreter [
	^self referenceTimesAndArgsForClosureInterpreter collect: [:ea| ea first]
]

{ #category : #reporting }
ShootoutTests class >> report: name time: millisecs reference: reference on: aStream [
	aStream
		cr;
		nextPutAll: name; cr;
		nextPutAll: ' took '; print: millisecs / 1000.0; nextPutAll: ' seconds'; cr; flush;
		nextPutAll: 'ratio: '; print: ((millisecs / reference) roundTo: 0.001);
		nextPutAll: '   % change: '; print: ((millisecs - reference * 100 / reference) roundTo: 0.01); nextPut: $%;
		cr; flush
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToDummyStream [
	"Transcript clear.
	 self runAllToDummyStream"
	^self runAllToDummyStreamVs: self referenceTimesForClosureInterpreter
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToDummyStreamVs: referenceTimes [
	"Transcript clear.
	 self runAllToDummyStreamVs: self referenceTimesForClosureInterpreter"
	"Transcript clear.
	 self runAllToDummyStreamVs: self referenceTimesForSqueakVM"
	^self runAllToDummyStreamVs: referenceTimes reportTo: Transcript
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToDummyStreamVs: referenceTimes reportTo: aStream [
	"Transcript clear.
	 self runAllToDummyStreamVs: self referenceTimesForClosureInterpreter"
	"Transcript clear.
	 self runAllToDummyStreamVs: self referenceTimesForSqueakVM"
	| times ratios geometricMean |
	times := Array new writeStream.
	ratios := Array new writeStream.
	(self standardSuiteTo: DummyStream basicNew) do:
		[:block | | benchmark reference t |
		benchmark := (self selectorForSimpleBlock: block) copyUpTo: $:.
		reference := referenceTimes at: benchmark asSymbol.
		Smalltalk garbageCollect.
		times nextPut: (t := Time millisecondsToRun: block).
		ratios nextPut: t asFloat / reference.
		self report: block decompile printString time: t reference: reference on: aStream].
	geometricMean := (ratios contents inject: 1 into: [:m :n| m * n]) raisedTo: 1 / ratios position.
	aStream
		nextPutAll: 'geometric mean '; print: (geometricMean roundTo: 0.001);
		nextPutAll: '   average speedup '; print: ((geometricMean - 1 * 100) roundTo: 0.01); nextPut: $%; cr; cr; flush.
	^times contents
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToInternalStream [
	"Transcript clear.
	 self runAllToInternalStream"
	^self runAllToInternalStreamVs: self referenceTimesForClosureInterpreter
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToInternalStreamVs: referenceTimes [
	"Transcript clear.
	 self runAllToInternalStreamVs: self referenceTimesForClosureInterpreter"
	"Transcript clear.
	 self runAllToInternalStreamVs: self referenceTimesForSqueakVM"
	| times ratios geometricMean |
	times := Array new writeStream.
	ratios := Array new writeStream.
	(self standardSuiteTo: (ByteString new: 10000) writeStream) do:
		[:block | | benchmark reference t |
		benchmark := (self selectorForSimpleBlock: block) copyUpTo: $:.
		reference := referenceTimes at: benchmark asSymbol.
		Smalltalk garbageCollect.
		times nextPut: (t := Time millisecondsToRun: block).
		ratios nextPut: t asFloat / reference.
		self report: block decompile printString time: t reference: reference on: Transcript].
	geometricMean := (ratios contents inject: 1 into: [:m :n| m * n]) raisedTo: 1 / ratios position.
	Transcript
		nextPutAll: 'geometric mean '; print: (geometricMean roundTo: 0.001);
		nextPutAll: '   average speedup '; print: ((geometricMean - 1 * 100) roundTo: 0.01); nextPut: $%; cr; cr; flush.
	^times contents
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToTranscript [
	"Transcript clear.
	 self runAllToTranscript"
	^self runAllToTranscriptVs: self referenceTimesForClosureInterpreter
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> runAllToTranscriptVs: referenceTimes [
	"Transcript clear.
	 self runAllToTranscriptVs: self referenceTimesForClosureInterpreter"
	"Transcript clear.
	 self runAllToTranscriptVs: self referenceTimesForSqueakVM"
	| times ratios geometricMean |
	times := Array new writeStream.
	ratios := Array new writeStream.
	(self standardSuiteTo: Transcript) do:
		[:block | | benchmark reference t |
		benchmark := (self selectorForSimpleBlock: block) copyUpTo: $:.
		reference := referenceTimes at: benchmark asSymbol.
		Smalltalk garbageCollect.
		times nextPut: (t := Time millisecondsToRun: block).
		ratios nextPut: t asFloat / reference.
		self report: block decompile printString time: t reference: reference on: Transcript].
	geometricMean := (ratios contents inject: 1 into: [:m :n| m * n]) raisedTo: 1 / ratios position.
	Transcript
		nextPutAll: 'geometric mean '; print: (geometricMean roundTo: 0.001);
		nextPutAll: '   average speedup '; print: ((geometricMean - 1 * 100) roundTo: 0.01); nextPut: $%; cr; cr; flush.
	^times contents
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> selectorForSimpleBlock: aBlock [
	| is |
	is := InstructionStream on: aBlock method.
	is pc: aBlock startpc.
	is scanFor:
		[:x| | selectorOrScanner |
		(selectorOrScanner := is selectorToSendOrSelf) ~~ is ifTrue:
			[^selectorOrScanner].
		false].
	^nil
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> standardSuiteTo: aStream [
	"revised up from
		{ [self nbody: 200000 to: stream].
		   [self binarytrees: 15 to: stream].
		   [self chameneosredux: 260000 to: stream].
		   [self threadring: 10000000 to: stream] }
	 on 6/15/2014"
	| reference nbodyCount binaryTreeDepth chameneosCount threadringCount |
	reference := self referenceTimesAndArgsForClosureInterpreter.
	nbodyCount := (reference at: #nbody) last.
	binaryTreeDepth := (reference at: #binarytrees) last.
	chameneosCount := (reference at: #chameneosredux) last.
	threadringCount := (reference at: #threadring) last.
	^{ [self nbody: nbodyCount to: aStream].
	     [self binarytrees: binaryTreeDepth to: aStream].
	     [self chameneosredux: chameneosCount to: aStream].
	     [self threadring: threadringCount to: aStream] }
]

{ #category : #platform }
ShootoutTests class >> stdin [
   ^StandardFileStream stdIn
]

{ #category : #platform }
ShootoutTests class >> stdout [
   ^StandardFileStream stdout
]

{ #category : #benchmarking }
ShootoutTests class >> threadRing: aSemaphore output: output [
   | first last |
   503 to: 1 by: -1 do: [:i|
      first := ShootoutThread named: i next: first done: aSemaphore output: output.
      last isNil ifTrue: [ last := first ].
   ].
   last nextThread: first.
   ^first 
]

{ #category : #'benchmark scripts' }
ShootoutTests class >> threadring [
  self threadring: self arg to: self stdout.
   ^''
]

{ #category : #benchmarking }
ShootoutTests class >> threadring: arg to: output [
   | done |
   (self threadRing: (done := Semaphore new) output: output) takeToken: arg.
   done wait
]
