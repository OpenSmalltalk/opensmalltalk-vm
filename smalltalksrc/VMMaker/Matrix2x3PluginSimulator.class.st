Class {
	#name : #Matrix2x3PluginSimulator,
	#superclass : #Matrix2x3Plugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #primitives }
Matrix2x3PluginSimulator >> primitiveComposeMatrix [
	| m1 m2 m3 |
	m2 := self stackMatrixValue: 1.
	m1 := self stackMatrixValue: 2.
	super primitiveComposeMatrix.
	interpreterProxy failed ifFalse:
		[m3 := self stackMatrixValue: 0.
		 self assert: m3 = (m1 composedWithLocal: m2)]
]

{ #category : #'simulation support' }
Matrix2x3PluginSimulator >> stackMatrixValue: n [
	| maybeMatrixOop |
	maybeMatrixOop := interpreterProxy stackValue: n.
	^((interpreterProxy isWords: maybeMatrixOop)
	  and: [(interpreterProxy slotSizeOf: maybeMatrixOop) = 6]) ifTrue:
		[MatrixTransform2x3 new
			basicAt: 1 put: (interpreterProxy fetchLong32: 0 ofObject: maybeMatrixOop);
			basicAt: 2 put: (interpreterProxy fetchLong32: 1 ofObject: maybeMatrixOop);
			basicAt: 3 put: (interpreterProxy fetchLong32: 2 ofObject: maybeMatrixOop);
			basicAt: 4 put: (interpreterProxy fetchLong32: 3 ofObject: maybeMatrixOop);
			basicAt: 5 put: (interpreterProxy fetchLong32: 4 ofObject: maybeMatrixOop);
			basicAt: 6 put: (interpreterProxy fetchLong32: 5 ofObject: maybeMatrixOop);
			yourself]
]
