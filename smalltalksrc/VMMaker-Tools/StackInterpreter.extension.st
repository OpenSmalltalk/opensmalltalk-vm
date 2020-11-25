Extension { #name : #StackInterpreter }

{ #category : #'*VMMaker-Tools' }
StackInterpreter >> stack [

	framePointer = nil
		ifTrue: [ self halt ].
	
	^ (VMStackFrame virtualMachine: self fp: framePointer) stack
]
