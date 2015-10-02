Extension { #name : #Collection }

{ #category : #'*VMMaker-printing' }
Collection >> storeStringBase: base [
	"This for bit/byte/word collections."
	^String streamContents: [:strm | self storeOn: strm base: base]
]
