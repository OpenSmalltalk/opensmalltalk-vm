Extension { #name : #GtTranscript }

{ #category : #'*VMMakerCompatibilityForPharo6' }
GtTranscript >> ensureCr [
	"do nothing"
	(self text isEmpty or: [ self text last == Character cr]) ifFalse: 
		[ self cr ]
]

{ #category : #'*VMMakerCompatibilityForPharo6' }
GtTranscript >> flush [
	"do nothing"
]

{ #category : #'*VMMakerCompatibilityForPharo6' }
GtTranscript >> next: anInteger put: aCharacter [ 
	"Make anObject be the next anInteger number of objects accessible by the 
	receiver. Answer anObject."
	
	1 to: anInteger do: [:i| self nextPut: aCharacter ].
	^ aCharacter
]
