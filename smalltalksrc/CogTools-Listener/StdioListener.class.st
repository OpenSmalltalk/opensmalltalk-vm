Class {
	#name : #StdioListener,
	#superclass : #Object,
	#instVars : [
		'quitOnEof',
		'stdin',
		'stdout',
		'stderr'
	],
	#category : #'CogTools-Listener'
}

{ #category : #'initialize-release' }
StdioListener >> initialize [
	quitOnEof := true.
	stdin := FileStream stdin.
	stdout := FileStream stdout.
	stderr := FileStream stderr
]

{ #category : #'run loop' }
StdioListener >> logError: errMsg inContext: aContext to: aStream [
	aStream nextPutAll: errMsg; cr.
	aContext errorReportOn: aStream.
	aStream cr
]

{ #category : #accessing }
StdioListener >> quitOnEof [
	^quitOnEof
]

{ #category : #accessing }
StdioListener >> quitOnEof: aBoolean [
	quitOnEof := aBoolean
]

{ #category : #'run loop' }
StdioListener >> run [
	[stdin atEnd] whileFalse:
		[| nextChunk |
		 stdout nextPutAll: 'squeak> '; flush.
		 nextChunk := stdin nextChunkNoTag.
		 [nextChunk notEmpty and: [nextChunk first isSeparator]] whileTrue:
			[nextChunk := nextChunk allButFirst].
		 Transcript cr; nextPutAll: nextChunk; cr; flush.
		 [stdout print: (Compiler evaluate: nextChunk); cr; flush]
			on: Error
			do: [:ex| self logError: ex description inContext: ex signalerContext to: stderr]].
	quitOnEof ifTrue:
		[Smalltalk snapshot: false andQuit: true]
]
