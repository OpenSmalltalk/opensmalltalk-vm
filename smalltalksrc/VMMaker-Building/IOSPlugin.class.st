Class {
	#name : #IOSPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Plugins-IOS'
}

{ #category : #primitives }
IOSPlugin >> primitiveShowKeyboard: showBoolean [
	<export: true>
	self primitive: #primitiveShowKeyboard parameters: #(Boolean).
	self sqShowKeyboard: showBoolean.
]
