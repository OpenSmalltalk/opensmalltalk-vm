Extension { #name : #SmartSyntaxPluginCodeGenerator }

{ #category : #'*vmmakerjs' }
SmartSyntaxPluginCodeGenerator classSide >> new [
	JSCodeGenerator isActive ifTrue: [^JSSmartSyntaxPluginCodeGenerator new].
	^super new
]
