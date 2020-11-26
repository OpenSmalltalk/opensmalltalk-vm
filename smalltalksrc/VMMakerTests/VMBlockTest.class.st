Class {
	#name : #VMBlockTest,
	#superclass : #VMInterpreterTests,
	#pools : [
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #supports }
VMBlockTest >> anEmptyMethod [
]

{ #category : #supports }
VMBlockTest >> installBlockClosureClass [
		| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: BlockClosure instSpec.
	memory setHashBitsOf: aClass to: ClassBlockClosureCompactIndex.
	memory
		storePointer: ClassBlockClosureCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : #supports }
VMBlockTest >> methodReturningABlock [
	
	^ []
	
]

{ #category : #testing }
VMBlockTest >> testPushClosureBytecodePushesClosure [

	| methodOop methodHeader previousMethodOop |
	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodReturningABlock.

	previousMethodOop := self createMethodOopFromPharoMethod:
		                     self class >> #anEmptyMethod.

	self installBlockClosureClass.
	"We want to avoid baseFrameReturn (base frame initialisation)"
	stackBuilder addNewFrame method: previousMethodOop.
	stackBuilder addNewFrame
		method: methodOop;
		receiver: memory trueObject.
	stackBuilder buildStack.
	methodHeader := memory methodHeaderOf: methodOop.

	interpreter instructionPointer:
		(interpreter initialIPForHeader: methodHeader method: methodOop) - 1.
	interpreter interpretWhile: [ interpreter method = methodOop ].

	self
		assert: (memory fetchClassOf: interpreter stackTop)
		equals: (memory classAtIndex: ClassBlockClosureCompactIndex)
]
