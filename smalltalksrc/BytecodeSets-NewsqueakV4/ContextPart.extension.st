Extension { #name : #ContextPart }

{ #category : #'*BytecodeSets-instruction decoding' }
ContextPart >> directedSuperSend: selector numArgs: numArgs [
	"Simulate the action of bytecodes that send a message with selector,
	 selector, starting the lookup above the class that is the value of the
	 association on top of stack. The arguments  of the message are found
	 in the top numArgs stack locations and the receiver just below them."

	| startClassAssociation receiver arguments |
	startClassAssociation := self pop.
	arguments := Array new: numArgs.
	numArgs to: 1 by: -1 do: [:i| arguments at: i put: self pop].
	receiver := self pop.
	^self
		send: selector
		to: receiver
		with: arguments
		lookupIn: startClassAssociation value superclass
]
