Extension { #name : #Oop }

{ #category : #'*vmmakerjs' }
Oop classSide >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg emitJSExpression: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Oop classSide >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg emitJSExpression: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Oop classSide >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asRawOopFrom: anInteger
]

{ #category : #'*vmmakerjs' }
Oop classSide >> jscgCanConvertFrom: anObject [

	^(anObject isKindOf: SmallInteger) not
]
