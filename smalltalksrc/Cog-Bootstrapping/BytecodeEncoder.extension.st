Extension { #name : #BytecodeEncoder }

{ #category : #'*Cog-instruction stream support' }
BytecodeEncoder class >> isBranchAt: pc in: method [
	"Answer whether the bytecode at pc is a conditional branch."

	self subclassResponsibility
]
