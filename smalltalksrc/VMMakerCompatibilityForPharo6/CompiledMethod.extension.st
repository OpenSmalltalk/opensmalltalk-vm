Extension { #name : #CompiledMethod }

{ #category : #'*VMMakerCompatibilityForPharo6-closures' }
CompiledMethod >> embeddedBlockClosures [
	| bms extractor scanner endPC encoderClass |
	bms := OrderedCollection new.
	scanner := self scanner.
	extractor := ClosureExtractor withAction: [:c| bms add: c] andScanner: scanner.
	endPC := self endPC.
	encoderClass := self encoderClass.
	[scanner pc <= endPC] whileTrue:
		[encoderClass interpretNextInstructionFor: extractor in: scanner].
	^bms
]
