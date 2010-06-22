Extension { #name : #SmallInteger }

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [

	cg generateCoerceToSmallIntegerObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [

	cg generateCoerceToSmallIntegerValueFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asIntegerValueFrom: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccgCanConvertFrom: anObject [

	^anObject class == self
]
