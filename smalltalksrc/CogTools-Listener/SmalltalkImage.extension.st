Extension { #name : #SmalltalkImage }

{ #category : #'*CogTools-Listener' }
SmalltalkImage >> snapshot: save andQuit: quit [
	^self snapshot: save andQuit: quit embedded: false
]
