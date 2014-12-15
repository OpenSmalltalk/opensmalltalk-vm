Extension { #name : #PositionableStream }

{ #category : #'*CogTools-Listener' }
PositionableStream >> nextChunkNoTag [
	"Answer the contents of the receiver, up to the next terminator character.
	 Doubled terminators indicate an embedded terminator character.
	 Unlike nextChunk, do not look for ]lang[ tags."
	| skippingSeparators terminator out ch |
	terminator := $!.
	skippingSeparators := true. "inline skipSeparators since restoreStateOf:with: is not reliable"
	out := WriteStream on: (String new: 1000).
	[(ch := self next) == nil] whileFalse:
		[ch == terminator ifTrue:
			[self peek == terminator
				ifTrue:"skip doubled terminator"
					[self next]
				ifFalse:
					[^out contents  "terminator is not doubled; we're done!"]].
		(skippingSeparators and: [ch isSeparator]) ifFalse:
			[out nextPut: ch.
			skippingSeparators := false]].
	^out contents
]
