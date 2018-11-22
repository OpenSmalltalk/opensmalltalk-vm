Extension { #name : #SequenceableCollection }

{ #category : #'*VMMaker-translation support' }
SequenceableCollection >> copyReplaceAll: oldSubstring with: newSubstring tokenish: tokenishBlock [
	"Answer a copy of the receiver in which all occurrences of
	 oldSubstring have been replaced by newSubstring.
	 tokenishBlock specifies what elements are in a token."

	| sequence startSearch currentIndex endIndex |
	sequence := self.
	startSearch := 1.
	[(currentIndex := sequence indexOfSubCollection: oldSubstring startingAt: startSearch)
		> 0] whileTrue: 
		[endIndex := currentIndex + oldSubstring size - 1.
		((currentIndex = 1
				or: [(tokenishBlock value: (sequence at: currentIndex-1)) not])
		  and: [endIndex = sequence size
				or: [(tokenishBlock value: (sequence at: endIndex+1)) not]])
			ifTrue: [sequence := sequence
					copyReplaceFrom: currentIndex
					to: endIndex
					with: newSubstring.
				startSearch := currentIndex + newSubstring size]
			ifFalse: [startSearch := currentIndex + 1]].
	^sequence

"Test case:
	'pid_t (*pid)(pid_t pid)' copyReplaceAll: 'pid' with: 'foo' tokenish: [:ch| ch = $_ or: [ch isAlphaNumeric]]"

]
