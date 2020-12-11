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
	
	self assert: methodBuilder buildMethodHeader equals: (memory integerValueOf: (memory fetchPointer: 0 ofObject: method)).
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
MethodBuilderTest >> testBytecodeAtForMethodWithNoLiteral [
	| bytecodeAddress |
	literals := { }.
	method := methodBuilder newMethod 
		bytecodes: #[ 1 2 3 4 5 6 7 8 9 ];
		literals: literals;
		buildMethod.

	bytecodeAddress := methodBuilder bytecodeAt: 1 forMethod: method.
	
	self assert: (memory byteAt: bytecodeAddress) equals: 1
]

{ #category : #running }
MethodBuilderTest >> testBytecodeAtForMethodWithOneLiteral [
	| bytecodeAddress |
	literals := { 1 }.
	method := methodBuilder newMethod 
		bytecodes: #[ 1 2 3 4 5 6 7 8 9 ];
		literals: literals;
		buildMethod.

	bytecodeAddress := methodBuilder bytecodeAt: 1 forMethod: method.
	
	self assert: (memory byteAt: bytecodeAddress) equals: 1
]

{ #category : #running }
MethodBuilderTest >> testBytecodeAtForMethodWithTwoLiteral [
	| bytecodeAddress |
	literals := { 1. 2 }.
	method := methodBuilder newMethod 
		bytecodes: #[ 1 2 3 4 5 6 7 8 9 ];
		literals: literals;
		buildMethod.

		bytecodeAddress := methodBuilder bytecodeAt: 1 forMethod: method.
	
	self assert: (memory byteAt: bytecodeAddress) equals: 1
]

{ #category : #running }
MethodBuilderTest >> testGeneratingCompiledMethod [
	method := methodBuilder newMethod bytecodes: #[ 1 2 3 4 5 6 7 8 ]; buildMethod.
	self assert: (memory isCompiledMethod: method).
]

{ #category : #running }
MethodBuilderTest >> testInstanciateMethodShouldTakeOneSlotForEightBytecodes [
	| numberOfByteCode |
	numberOfByteCode := 8.
	method := methodBuilder newMethod bytecodes: #[ 1 2 3 4 5 6 7 8 ]; buildMethod.

	"should equal the header (1) + the number of bytecodes divided by wordsize"
	self assert: methodBuilder slotSize equals: 1 + (numberOfByteCode / wordSize) ceiling..
]

{ #category : #running }
MethodBuilderTest >> testInstanciateMethodShouldTakeTwoSlotForNineBytecodes [
	| numberOfByteCode |
	numberOfByteCode := 9.
	method := methodBuilder newMethod bytecodes: #[ 1 2 3 4 5 6 7 8 9 ]; buildMethod.

	"should equal the header (1) + the number of bytecodes divided by wordsize"
	self assert: methodBuilder slotSize equals: 1 + (numberOfByteCode / wordSize) ceiling.
]

{ #category : #running }
MethodBuilderTest >> testSecondBytecodeAtForMethodWithOneLiteral [
	| bytecodeAddress |
	literals := { 1 }.
	method := methodBuilder newMethod 
		bytecodes: #[ 1 2 3 4 5 6 7 8 9 ];
		literals: literals;
		buildMethod.

	bytecodeAddress := methodBuilder bytecodeAt: 2 forMethod: method.
	
	self assert: (memory byteAt: bytecodeAddress) equals: 2
]
