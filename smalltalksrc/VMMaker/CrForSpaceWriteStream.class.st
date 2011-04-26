Class {
	#name : #CrForSpaceWriteStream,
	#superclass : #WriteStream,
	#category : #'VMMaker-Building'
}

{ #category : #'character writing' }
CrForSpaceWriteStream >> space [
	"Append a cr character instead of a space character to the receiver."

	self cr
]
