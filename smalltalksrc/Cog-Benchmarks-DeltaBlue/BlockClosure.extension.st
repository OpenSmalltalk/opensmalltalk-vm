Extension { #name : #BlockClosure }

{ #category : #'*Cog-method prototypes' }
BlockClosure >> BlockClosurePROTOTYPEsimulateValueWithArguments: anArray caller: aContext [
	"Simulate the valueWithArguments: primitive. Fail if anArray is not an array of the right arity."
	| newContext sz |
	newContext := (MethodContext newForMethod: outerContext method)
						setSender: aContext
						receiver: outerContext receiver
						method: outerContext method
						closure: self
						startpc: startpc.
	((newContext objectClass: anArray) ~~ Array
	 or: [numArgs ~= anArray size]) ifTrue:
		[^ContextPart primitiveFailTokenFor: nil].
	sz := self basicSize.
	newContext stackp: sz + numArgs.
	1 to: numArgs do:
		[:i| newContext at: i put: (anArray at: i)].
	1 to: sz do:
		[:i| newContext at: i + numArgs put: (self at: i)].
	^newContext
]
