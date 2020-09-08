Class {
	#name : #MethodBuilderTest,
	#superclass : #VMInterpreterTests,
	#instVars : [
		'literals',
		'numberOfArguments',
		'numberOfTemporaries',
		'bytecodes',
		'isSmall',
		'isPrimitive',
		'methodHeader',
		'method'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #running }
MethodBuilderTest >> testAddingBytecodesDoesntOverrideHeader [
	method := methodBuilder newMethod buildMethod.
	
	self assert: methodBuilder methodHeader equals: (memory integerValueOf: (memory fetchPointer: 0 ofObject: method)).
]

{ #category : #running }
MethodBuilderTest >> testAllocatingMethodDoesntOverflows [
	method := methodBuilder newMethod; buildMethod.

	"When filling the method with bytecodes/literals, we are writing the memory directly"
	"We need to not overflow and corrupt the next memory"
	"This first assertion checks that we didn't corrupt the next memory"
	memory assertInnerValidFreeObject: (memory freeLists at: 0).
	"And if we didn't corrupt the memory, we should be able to instantiate another one !"
	self shouldnt:[ methodBuilder newMethod; buildMethod ] raise: AssertionFailure
]

{ #category : #running }
MethodBuilderTest >> testBuildEmptyMethodIsCompiledMethod [
	"checking the format"
	method := methodBuilder newMethod; buildMethod.
	self assert: (memory isCompiledMethod: method)
]

{ #category : #running }
MethodBuilderTest >> testInstanciateMethodShouldTakeOneSlotForEightBytecodes [
	method := methodBuilder newMethod bytecodes: #[ 1 2 3 4 5 6 7 8 ]; buildMethod.

	"should equal the header (1) + the number of bytecodes divided by 8"
	self assert: methodBuilder slotSize equals: 2.
]

{ #category : #running }
MethodBuilderTest >> testInstanciateMethodShouldTakeTwoSlotForNineBytecodes [
	method := methodBuilder newMethod bytecodes: #[ 1 2 3 4 5 6 7 8 9 ]; buildMethod.

	"should equal the header (1) + the number of bytecodes divided by 8"
	self assert: methodBuilder slotSize equals: 3.
]
