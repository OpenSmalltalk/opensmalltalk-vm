Extension { #name : #Boolean }

{ #category : #'*VMMaker-interpreter simulator' }
Boolean >> asBooleanObj [
	^(Notification new tag: #getInterpreter; signal)
		ifNotNil: [:interpreter| interpreter booleanObjectOf: self]
		ifNil: [self]
]

{ #category : #'*VMMaker-C translation' }
Boolean >> asCCodeInlineStrategy [

	^ CCodeGeneratorInlineStrategy from: self
]

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToBooleanObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToBooleanValueFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asBooleanValueFrom: anInteger
]

{ #category : #'*VMMaker-interpreter simulator' }
Boolean >> isBreakpointFor: address [
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Boolean >> menuPrompt [
	^' (CLICK STEPPING!!)'
]

{ #category : #'*VMMaker-interpreter simulator' }
Boolean >> shouldStopIfAtPC: address [
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Boolean >> singleStepRequiredToTriggerIn: aCogit [
	^self
]
