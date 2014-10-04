Extension { #name : #VMPluginCodeGenerator }

{ #category : #'*vmmakerjs' }
VMPluginCodeGenerator classSide >> new [
	JSCodeGenerator isActive ifTrue: [^JSPluginCodeGenerator new].
	^super new
]
