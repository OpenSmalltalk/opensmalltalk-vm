Extension { #name : #CodeHolder }

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> selectedTranslateInlinedC [
	"Answer text to show in a code pane when in showing translate-to-inlined-C mode"

	| class selector |
	class := self selectedClassOrMetaClass.
	selector := self selectedMessageName.
	^ class asInlinedCString: selector

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> selectedTranslateToC [
	"Answer text to show in a code pane when in showing translate-to-C mode"

	| class selector |
	class := self selectedClassOrMetaClass.
	selector := self selectedMessageName.
	^ class asCString: selector

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> showTranslateInlinedC: aBoolean [
	"Set the translate to inlined C toggle as indicated"

	self contentsSymbol: (aBoolean ifFalse: [#source] ifTrue: [#translateInlinedC])
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> showTranslateToC: aBoolean [
	"Set the translate to C toggle as indicated"

	self contentsSymbol: (aBoolean ifFalse: [#source] ifTrue: [#translateToC])
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> showingTranslateInlinedC [
	"Answer whether the receiver should attempt to show translated inlined C source
	code rather than, say, source code"

	^ self contentsSymbol == #translateInlinedC

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> showingTranslateInlinedCString [
	"Answer a string characterizing whether translation to inlined C source is showing"

	^ (self showingTranslateInlinedC
		ifTrue:
			['<yes>']
		ifFalse:
			['<no>']), 'translate inlined C'
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> showingTranslateToC [
	"Answer whether the receiver should attempt to show translated C source code
	rather than, say, source code"

	^ self contentsSymbol == #translateToC

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> showingTranslateToCString [
	"Answer a string characterizing whether translation to C source is showing"

	^ (self showingTranslateToC
		ifTrue:
			['<yes>']
		ifFalse:
			['<no>']), 'translate to C'
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> toggleShowingTranslateInlinedC [
	"Toggle the setting of the translateInlinedC flag, unless there are unsubmitted edits that the user declines to discard"

	| wasShowing |
	self okToChange ifTrue:
		[wasShowing := self showingTranslateInlinedC.
		self restoreTextualCodingPane.
		self showTranslateInlinedC: wasShowing not.
		self setContentsToForceRefetch.
		self contentsChanged]


]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
CodeHolder >> toggleShowingTranslateToC [
	"Toggle the setting of the translateToC flag, unless there are unsubmitted edits that the user declines to discard"

	| wasShowing |
	self okToChange ifTrue:
		[wasShowing := self showingTranslateToC.
		self restoreTextualCodingPane.
		self showTranslateToC: wasShowing not.
		self setContentsToForceRefetch.
		self contentsChanged]


]
