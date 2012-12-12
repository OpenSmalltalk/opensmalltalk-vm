Extension { #name : #Symbol }

{ #category : #'*VMMaker-interpreter simulator' }
Symbol >> coerceTo: cTypeString sim: interpreterSimulator [

	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Symbol >> defined [
	"To allow constructs such as self cppIf: #'SA_NOCLDSTOP' defined ifTrue: [...].
	We could go look for a definition but likely there won't be one."
	^false
]
