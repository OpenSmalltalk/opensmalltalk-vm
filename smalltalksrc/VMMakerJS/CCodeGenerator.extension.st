Extension { #name : #CCodeGenerator }

{ #category : #'*vmmakerjs' }
CCodeGenerator classSide >> new [
	JSCodeGenerator isActive ifTrue: [^JSCodeGenerator new].
	^super new
]
