Class {
	#name : #CoInterpreterTests,
	#superclass : #TestCase,
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #tests }
CoInterpreterTests >> testMinimumUnusedHeadroom [
	"self new testMinimumUnusedHeadroom"
	| ci bpw |
	CoInterpreter initializeWithOptions: Dictionary new.
	ci := CogVMSimulator new.
	bpw := ci objectMemory wordSize.
	ci initStackPagesForTests.
	self assert: ci minimumUnusedHeadroom = ci stackPageByteSize.
	0 to: ci stackPageByteSize - 1 by: bpw do:
		[:p|
		0 to: ci numStackPages - 1 do:
			[:i| | page |
			page := ci stackPages stackPageAt: i.
			ci longAt: page baseAddress - p put: 1].
		self assert: ci minimumUnusedHeadroom = (ci stackPageByteSize - (p + bpw))]
]
