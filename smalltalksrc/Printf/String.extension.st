Extension { #name : #String }

{ #category : #'*printf' }
String >> asArgumentArrayForFormatString [

	^{self}
]

{ #category : #'*printf' }
String >> printf [
	^ (self indexOf: $%) ~= 0
		ifTrue: [ self ]
		ifFalse: [ (PrintfFormatString new setFormat: self) printf: #() ]
]

{ #category : #'*printf' }
String >> printf: arguments [
	"Answer the string that results from applying the receiver
	 as a printf-style format string to the arguments.  For example
		'Hello %d world!' printf: {Date today year}"
	^(PrintfFormatString new setFormat: self)
		printf: arguments;
		string
]
