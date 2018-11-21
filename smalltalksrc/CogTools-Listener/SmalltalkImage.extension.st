Extension { #name : #SmalltalkImage }

{ #category : #'*CogTools-Listener' }
SmalltalkImage >> quit [
	self snapshot: false andQuit: true
]
