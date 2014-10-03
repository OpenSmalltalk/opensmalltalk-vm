Extension { #name : #Object }

{ #category : #'*vmmakerjs' }
Object class >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg emitJSExpression: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Object class >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg emitJSExpression: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Object class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asKindOf: self from: anInteger
]

{ #category : #'*vmmakerjs' }
Object class >> jscgCanConvertFrom: anObject [

	^anObject isKindOf: self
]

{ #category : #'*vmmakerjs' }
Object class >> jscgDeclareJSForVar: aSymbolOrString [

	^'var ', aSymbolOrString
]
