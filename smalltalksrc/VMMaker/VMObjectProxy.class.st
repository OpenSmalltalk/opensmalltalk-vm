"
A VMObjectProxy is a wraper for an oop in the VM, that provides limited access to that oop as an object.

"
Class {
	#name : #VMObjectProxy,
	#superclass : #Object,
	#instVars : [
		'coInterpreter',
		'oop',
		'objectMemory'
	],
	#category : 'VMMaker-Support'
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
	shortPrint first = $= ifTrue:
		[shortPrint := shortPrint allButFirst].
	aStream nextPutAll: ' for '; nextPutAll: shortPrint
]

{ #category : #accessing }
VMObjectProxy >> selector [
	| selector |
	selector := coInterpreter maybeSelectorOfMethod: oop.
	^coInterpreter stringOf: selector
]

{ #category : #printing }
VMObjectProxy >> storeOn: aStream [
	"We don't care about storing these things properly.  Doing so involves printing an entire VM.
	 So simply print and hence get debuggable CompiledMethods whose literals are VMObjectProxys."
	^self printOn: aStream
]
