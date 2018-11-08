Extension { #name : #CompiledMethod }

{ #category : #'*CogTools-method introspection' }
CompiledMethod >> methodPCData [
	"If the method is linked to a cogit method, answers the values of the bytecode and
	 machine code pc pairs which are mapped to each other in the VM.  The first two
	 pairs have nil byetcode pcs and map to the checked and unchecked entrypoints
	 for methods and the no-context-switch and normal entries for blocks."
	<primitive: 'primitiveMethodPCData' module:''>
	^#()
]
