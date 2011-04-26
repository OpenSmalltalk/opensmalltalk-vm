Class {
	#name : #VMObjectProxy,
	#superclass : #Object,
	#instVars : [
		'coInterpreter',
		'oop',
		'objectMemory'
	],
	#category : #'VMMaker-Support'
}

{ #category : #'initialize-release' }
VMObjectProxy >> for: aCompiledMethodOop coInterpreter: aCoInterpreter objectMemory: anObjectMemory [
	oop := aCompiledMethodOop.
	coInterpreter := aCoInterpreter.
	objectMemory := anObjectMemory
]
