Extension { #name : #Symbol }

{ #category : #'*VMMaker-C translation' }
Symbol >> asCCodeInlineStrategy [

	^ CCodeGeneratorInlineStrategy from: self
]

{ #category : #'*VMMaker-interpreter simulator' }
Symbol >> coerceTo: cTypeString sim: interpreterSimulator [

	^self
]
