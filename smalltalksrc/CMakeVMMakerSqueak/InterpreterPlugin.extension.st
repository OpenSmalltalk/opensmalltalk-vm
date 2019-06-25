Extension { #name : #InterpreterPlugin }

{ #category : #'*CMakeVMMakerSqueak' }
InterpreterPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [ 

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: nil
]
