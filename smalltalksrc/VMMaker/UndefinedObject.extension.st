Extension { #name : #UndefinedObject }

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> addBreakpoint: address [
	^address
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> asIntegerPtr [
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> asUnsignedInteger [
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> asUnsignedIntegerPtr [
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> isActiveBreakpoint [
	^false
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> isBreakpointFor: address [
	^false
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> menuPrompt [
	^''
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> shouldStopIfAtPC: address [
	^true
]

{ #category : #'*VMMaker-interpreter simulator' }
UndefinedObject >> singleStepRequiredToTriggerIn: aCogit [
	^false
]
