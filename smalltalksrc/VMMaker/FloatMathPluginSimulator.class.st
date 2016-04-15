"
Float math plugin simulation for the VM simulator
"
Class {
	#name : #FloatMathPluginSimulator,
	#superclass : #FloatMathPlugin,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #translation }
FloatMathPluginSimulator class >> shouldBeTranslated [
"This class should not be translated"
	^false
]

{ #category : #'float primitives' }
FloatMathPluginSimulator >> isnan: result [
	^result isNaN
]
