Extension { #name : #WriteStream }

{ #category : #'*VMMaker-logging' }
WriteStream >> fflush [
	"compatibility to map the stdio fflush(FILE *) routine onto flush"
	self flush
]
