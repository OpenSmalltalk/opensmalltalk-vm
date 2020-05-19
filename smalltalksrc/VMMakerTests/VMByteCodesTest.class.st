Class {
	#name : #VMByteCodesTest,
	#superclass : #VMSpurMemoryManagerTest,
	#instVars : [
		'stackMemoryStartAddress',
		'stackMemoryEndAddress',
		'bytecodeTable',
		'interpreter'
	],
	#category : #VMMakerTests
}

{ #category : #'helper-interpretation' }
VMByteCodesTest >> assert: aBlock pushed: anOop [
	| oldStackSize |
	oldStackSize := interpreter stackPointer.
	
	aBlock value.
	
	self assert: interpreter stackPointer equals: oldStackSize - memory wordSize.
	self assert: interpreter stackTop equals: anOop.
	
]

{ #category : #'helper-frame' }
VMByteCodesTest >> frameBuilder [
	^ VMFrameBuilderForTest new
		initializeForTest: self;
		yourself

]

{ #category : #'helper-interpret' }
VMByteCodesTest >> interpret: aBlock [
	interpreter internalizeIPandSP.
	aBlock value.
	interpreter externalizeIPandSP.

]

{ #category : #running }
VMByteCodesTest >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	super setUp.
	
	memory nilObject: (self newObjectWithSlots: 0).
	memory trueObject: (self newObjectWithSlots: 0).
	memory falseObject: (self newObjectWithSlots: 0).
	
	"We don't access its contents, but we need it to be after nil, true and false"
	memory hiddenRootsObject: (self newObjectWithSlots: 0).
	interpreter := memory interpreter.
	
	"stackMemoryStartAddress := initialAddress + self initialCodeSize.
	stackMemoryEndAddress := stackMemoryStartAddress + stackSpaceSize."
	
	self initializeOldSpaceForScavenger.

	


]

{ #category : #'test-push-simple' }
VMByteCodesTest >> testPushConstantFalseBytecode [
	self frameBuilder buildFrame.
	self
		assert: [ self interpret: [ interpreter pushConstantFalseBytecode ] ]
		pushed: memory falseObject
]

{ #category : #'test-push-simple' }
VMByteCodesTest >> testPushConstantMinusOneBytecode [

	self frameBuilder buildFrame.
	self
		assert: [ self interpret: [ interpreter pushConstantMinusOneBytecode ] ]
		pushed: (memory integerObjectOf: -1)
]

{ #category : #'test-push-simple' }
VMByteCodesTest >> testPushConstantNilBytecode [
	self frameBuilder buildFrame.
	self
		assert: [ self interpret: [ interpreter pushConstantNilBytecode ] ]
		pushed: memory nilObject
]

{ #category : #'test-push-simple' }
VMByteCodesTest >> testPushConstantOneBytecode [

	self frameBuilder buildFrame.
	self
		assert: [ self interpret: [ interpreter pushConstantOneBytecode ] ]
		pushed: (memory integerObjectOf: 1)
]

{ #category : #'test-push-simple' }
VMByteCodesTest >> testPushConstantReceiverBytecode [
	| intReceiver |
	intReceiver := memory integerObjectOf: 42.
	self frameBuilder
		receiver: intReceiver;
		buildFrame.
	self
		assert: [ self interpret: [ interpreter pushReceiverBytecode ] ]
		pushed: intReceiver
]

{ #category : #'test-push-simple' }
VMByteCodesTest >> testPushConstantTrueBytecode [
	self frameBuilder buildFrame.
	self
		assert: [ self interpret: [ interpreter pushConstantTrueBytecode ] ]
		pushed: memory trueObject
]
