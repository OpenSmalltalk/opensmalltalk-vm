Extension { #name : #TNotImplementedNode }

{ #category : #'*vmmakerjs' }
TNotImplementedNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	"Emit a comment only"

	aStream cr; nextPutAll: '/*** ';
		nextPutAll: self printString;
		nextPutAll: ' cannot translate: '; cr;
		nextPutAll: parseNode printString;
		cr; nextPutAll: ' ***/'; cr

]
