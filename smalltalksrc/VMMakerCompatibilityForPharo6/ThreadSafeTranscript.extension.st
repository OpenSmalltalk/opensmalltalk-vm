Extension { #name : #ThreadSafeTranscript }

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
ThreadSafeTranscript >> crtab [
	self critical: [stream crtab]
]

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
ThreadSafeTranscript >> ensureCr [
	(stepContents notEmpty and: [stepContents last ~~ Character cr]) ifTrue:
		[ self nextPut: Character cr]
]

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
ThreadSafeTranscript >> next: anInteger put: anObject [
	"This is supposed to be a fucking WriteStream.  Why am I doing donkey work like this??"
	self critical: [stream next: anInteger put: anObject]
]
