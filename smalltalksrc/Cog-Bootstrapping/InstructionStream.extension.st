Extension { #name : #InstructionStream }

{ #category : #'*Cog-testing' }
InstructionStream >> willBranch [
	"Answer whether the next bytecode is a conditional branch."
	| method |
	method := self method.
	^method encoderClass isBranchAt: pc in: method
]
