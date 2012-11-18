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

{ #category : #accessing }
VMObjectProxy >> coInterpreter [
	"Answer the value of coInterpreter"

	^ coInterpreter
]

{ #category : #'initialize-release' }
VMObjectProxy >> for: aCompiledMethodOop coInterpreter: aCoInterpreter objectMemory: anObjectMemory [
	oop := aCompiledMethodOop.
	coInterpreter := aCoInterpreter.
	objectMemory := anObjectMemory
]

{ #category : #testing }
VMObjectProxy >> isCurrentImageFacade [
	^false
]

{ #category : #'symbolic printing' }
VMObjectProxy >> key [
	"For InstructionPrinter>>pushLiteralVariable:"
	^coInterpreter stringOf: (objectMemory fetchPointer: 0 ofObject: oop)
]

{ #category : #accessing }
VMObjectProxy >> objectMemory [
	"Answer the value of objectMemory"

	^ objectMemory
]

{ #category : #accessing }
VMObjectProxy >> oop [
	"Answer the value of oop"

	^ oop
]

{ #category : #printing }
VMObjectProxy >> printOn: aStream [
	| shortPrint |
	shortPrint := [coInterpreter shortPrint: oop]
				on: Error
				do: [:ex| ^super printOn: aStream].
	super printOn: aStream.
	aStream nextPutAll: ' for '; nextPutAll: shortPrint
]
