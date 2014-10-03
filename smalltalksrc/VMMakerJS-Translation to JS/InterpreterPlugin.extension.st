Extension { #name : #InterpreterPlugin }

{ #category : #'*vmmakerjs-override' }
InterpreterPlugin classSide >> moduleExtension [
	Smalltalk at: #JSCodeGenerator ifPresent: [:js | js isActive ifTrue: [^'.js']].
	^ self isCPP ifTrue: ['.cpp'] ifFalse: ['.c']
]
