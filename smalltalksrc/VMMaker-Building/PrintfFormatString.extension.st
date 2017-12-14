Extension { #name : #PrintfFormatString }

{ #category : #'*VMMaker-C code generation' }
PrintfFormatString >> transformForVMMaker [
	[outputStream nextPutAll: string next. 
	 format atEnd] whileFalse:
		[outputStream nextPutAll: format next transformForVMMaker].
	"any remainder is string, if so append to outputStream"
	string atEnd ifFalse: [outputStream nextPutAll: string next].
	^outputStream contents
]
