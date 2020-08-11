Class {
	#name : #VMMockContext,
	#superclass : #VMMockObject,
	#instVars : [
		'sender',
		'instructionPointer'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #accessing }
VMMockContext >> fetchPointer: anInteger [ 

	"sender"
	anInteger = 0
		ifTrue: [ ^ sender ].

	"Instruction pointer"
	anInteger = 1
		ifTrue: [ ^ objectMemory integerObjectOf: instructionPointer ].

	"stack pointer"
	anInteger = 2
		ifTrue: [ ^ objectMemory integerObjectOf: 0 ].
		
	"method"
	anInteger = 3
		ifTrue: [ ^ self methodAddress ].

	"closure"
	anInteger = 4
		ifTrue: [ ^ objectMemory nilObject ].

	"receiver"
	anInteger = 5
		ifTrue: [ ^ objectMemory nilObject ].
	self halt
]

{ #category : #accessing }
VMMockContext >> initialize [

	super initialize.
	sender := objectMemory nilObject.
	instructionPointer := self method initialPC.
]

{ #category : #accessing }
VMMockContext >> method [

	^ self class >> #method
]

{ #category : #accessing }
VMMockContext >> methodAddress [

	^ objectMemory addressOf: self method
]

{ #category : #accessing }
VMMockContext >> size [

	^ self method frameSize
]

{ #category : #accessing }
VMMockContext >> storePointer: anInteger withValue: anOop [

	"sender"
	anInteger = 0
		ifTrue: [ ^ sender := anOop ].

	"Instruction pointer"
	anInteger = 1
		ifTrue: [ ^ instructionPointer := objectMemory objectFor: anOop ].

	self halt.
]
