Extension { #name : #TranscriptStream }

{ #category : #'*VMMaker' }
TranscriptStream >> getText [
	^ self contents
]

{ #category : #'*VMMaker-JITSimulation-testing' }
TranscriptStream >> isTranscriptStream [
	^true
]
