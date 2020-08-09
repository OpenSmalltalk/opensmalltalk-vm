Extension { #name : #WriteStream }

{ #category : #'*Printf-printing' }
WriteStream >> f: printfString printf: arguments [
	"Use the printf convention to output on the receiver."
	^(PrintfFormatString new setFormat: printfString)
		f: self
		printf: arguments
]
