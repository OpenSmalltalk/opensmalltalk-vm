Extension { #name : #BalloonEngine }

{ #category : #'*VMMaker-InterpreterSimulation' }
BalloonEngine >> simulatePrimitive: aString args: args [ 
	"simulate primitives in RSqueak"
	| proxy bb |
	Smalltalk
		at: #BalloonEngineSimulation
		ifPresent: [:be | 
			proxy := InterpreterProxy new.
			proxy synthesizeStackFor: self with: args.
			bb := be simulatorClass new.
			bb setInterpreter: proxy.
			bb initialiseModule.
			"rendering state is loaded in the primitive implementations"
			bb perform: aString asSymbol.
			^ proxy stackValue: 0].
]
