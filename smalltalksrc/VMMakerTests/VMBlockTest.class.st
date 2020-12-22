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

{ #category : #helpers }
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

{ #category : #supports }
VMBlockTest >> methodReturningABlockInsideABlock [
	
	[^[]] value
	
]

{ #category : #supports }
VMBlockTest >> methodReturningABlockWithTwoArguments [
	
	^ [:a :b]
	
]

{ #category : #supports }
VMBlockTest >> methodWithLocalReturningABlock [

	| a |
	a:= 1.
	^ [ a ]
]

{ #category : #testing }
VMBlockTest >> testCreatingABlockClosureShouldCopyUsedMethodVariable [

	| methodOop previousMethodOop |
	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodWithLocalReturningABlock.

	previousMethodOop := self createMethodOopFromPharoMethod:
		                     self class >> #anEmptyMethod.

	self installBlockClosureClass.
	"We want to avoid baseFrameReturn (base frame initialisation)"
	stackBuilder addNewFrame method: previousMethodOop.
	stackBuilder addNewFrame
		method: methodOop;
		receiver: memory trueObject.
	stackBuilder buildStack.
	
	interpreter instructionPointer: (methodBuilder bytecodeAt: 0 forMethod: methodOop).
	interpreter interpretWhile: [ interpreter method = methodOop ].

	"We assign 1 to the local variable of the method, see methodWithLocalReturningABlock"
	self
		assert: (memory fetchPointer: ClosureFirstCopiedValueIndex ofObject: interpreter stackTop) equals: (memory integerObjectOf: 1).

]

{ #category : #testing }
VMBlockTest >> testCreatingABlockClosureShouldHaveCorrectPC [

	| methodOop previousMethodOop |
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
	
	interpreter instructionPointer: (methodBuilder bytecodeAt: 0 forMethod: methodOop).
	interpreter interpretWhile: [ interpreter method = methodOop ].

	"hard code for now should be modified"
	self
		assert: (memory fetchPointer: ClosureStartPCIndex ofObject: interpreter stackTop) equals: (memory integerObjectOf: 29).

]

{ #category : #testing }
VMBlockTest >> testCreatingABlockClosureShouldHaveOuterContextObject [

	| methodOop previousMethodOop |
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
	
	interpreter instructionPointer: (methodBuilder bytecodeAt: 0 forMethod: methodOop).
	interpreter interpretWhile: [ interpreter method = methodOop ].

	"Currently fails because the stack frame is not overriden.
	So the interpreter considers it's still married even thought the stack frame is already dead"

	self
		assert: (interpreter isWidowedContext: (memory outerContextOf: interpreter stackTop))

]

{ #category : #testing }
VMBlockTest >> testCreatingABlockWithoutArgumentsClosureShouldHaveNoArgument [

	| methodOop previousMethodOop |
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
	
	interpreter instructionPointer: (methodBuilder bytecodeAt: 0 forMethod: methodOop).

	interpreter interpretWhile: [ interpreter method = methodOop ].

	self
		assert: (memory fetchPointer: ClosureNumArgsIndex ofObject: interpreter stackTop) equals: (memory integerObjectOf: 0).

]

{ #category : #testing }
VMBlockTest >> testPushClosureBytecodePushesClosure [

	| methodOop previousMethodOop |
	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodReturningABlock.

	previousMethodOop := self createMethodOopFromPharoMethod:
		                     self class >> #anEmptyMethod.

	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodReturningABlock.

	self installBlockClosureClass.
	"We want to avoid baseFrameReturn (base frame initialisation)"
	stackBuilder addNewFrame method: previousMethodOop.
	stackBuilder addNewFrame
		method: methodOop;
		receiver: memory trueObject.
	stackBuilder buildStack.
	
	interpreter interpretWhile: [ interpreter method = methodOop ].

	self
		assert: (memory fetchClassOf: interpreter stackTop)
		equals: (memory classAtIndex: ClassBlockClosureCompactIndex)
]
