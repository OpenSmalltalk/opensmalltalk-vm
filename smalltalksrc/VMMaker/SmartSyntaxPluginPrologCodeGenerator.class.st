"
SmartSyntaxPluginPrologCodeGenerator is an abstract superclass for two subclasses that generate the validations and assignments at the beginning of SmartSyntaxInterpreterPlugin primitives in response to the primitive:parameters:... sends.
"
Class {
	#name : #SmartSyntaxPluginPrologCodeGenerator,
	#superclass : #Object,
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #utilities }
SmartSyntaxPluginPrologCodeGenerator >> stackAccessorFor: index [
	self assert: index isInteger.
	^'(interpreterProxy stackValue: ', (index printString, ')')
]
