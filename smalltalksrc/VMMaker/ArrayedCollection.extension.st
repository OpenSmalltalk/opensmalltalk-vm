Extension { #name : #ArrayedCollection }

{ #category : #'*VMMaker-simulated image growing' }
ArrayedCollection >> copyGrownBy: numberOfElements [
	"make a bigger copy of this collection - increase the size by numberOfElements and copy all the current elements into the bottom of the new copy"

	^(self class new: self size + numberOfElements) replaceFrom: 1 to: self size with: self
]
