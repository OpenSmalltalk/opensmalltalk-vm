Extension { #name : #BitBlt }

{ #category : #'*VMMaker-Interpreter' }
BitBlt >> copyBitsSimulated [
	^ BitBltSimulation copyBitsFrom: self
]

{ #category : #'*VMMaker-Interpreter' }
BitBlt >> copyBitsSimulated: alpha [
	^ BitBltSimulation copyBitsFrom: self
]

{ #category : #'*VMMaker-Interpreter' }
BitBlt >> simulatePrimitive: aString args: args [ 
	"simulate primitives in RSqueak"
	| proxy bb |
	proxy := InterpreterProxy new.
	proxy synthesizeStackFor: self with: args.
	bb := BitBltSimulation simulatorClass new.
	bb setInterpreter: proxy.
	bb initialiseModule.
	"rendering state is loaded in the primitive implementations"
	bb perform: aString asSymbol.
	^ proxy stackValue: 0

]
