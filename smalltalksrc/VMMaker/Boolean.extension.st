Extension { #name : #Boolean }

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asBooleanValueFrom: anInteger on: aStream 
]

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [

	cg generateCoerceToBooleanObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [

	cg generateCoerceToBooleanValueFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Boolean class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asBooleanValueFrom: anInteger
]
