Class {
	#name : #StackBuilderTest,
	#superclass : #VMByteCodesTest,
	#instVars : [
		'builder',
		'frame',
		'stackElement1',
		'stackElement2',
		'instructionPointer',
		'receiver',
		'context',
		'temp1',
		'temp2',
		'method'
	],
	#category : #VMMakerTests
}

{ #category : #'helper-frame' }
StackBuilderTest >> addComplexFrame [
	builder := VMStackBuilder new
		interpreter: interpreter; 
		memory: memory;
		yourself.
	frame := builder addNewFrame.
	instructionPointer := 3.
	frame beSuspendedAt: instructionPointer.

	stackElement1 := memory integerObjectOf: 4.
	stackElement2 := memory integerObjectOf: 5.
	frame stack: { stackElement1. stackElement2 }.
	
	temp1 := memory integerObjectOf: 6.
	temp2 := memory integerObjectOf: 7.
	frame temps: { temp1. temp2 }.

	receiver := memory integerObjectOf: 8.
	frame receiver: receiver.
	context := memory integerObjectOf: 9.
	frame context: context.

	method := memory integerObjectOf: 10.
	frame method: method.
		
]

{ #category : #offset }
StackBuilderTest >> offsetCallerFP [
	^ self offsetMethod + 1
]

{ #category : #offset }
StackBuilderTest >> offsetContext [ 
	^ self offsetReceiver + 1
]

{ #category : #offset }
StackBuilderTest >> offsetFlags [
	^ self offsetContext + 1
]

{ #category : #offset }
StackBuilderTest >> offsetInstructionPointer [
	^ 0
]

{ #category : #offset }
StackBuilderTest >> offsetMethod [
	^ self offsetFlags + 1
]

{ #category : #offset }
StackBuilderTest >> offsetReceiver [
	^ self offsetTemp1 + 1 
]

{ #category : #offset }
StackBuilderTest >> offsetStackElement1 [
	^ self offsetStackElement2 + 1
]

{ #category : #offset }
StackBuilderTest >> offsetStackElement2 [
	^ self offsetInstructionPointer + 1
]

{ #category : #offset }
StackBuilderTest >> offsetTemp1 [
	^ self offsetTemp2 + 1
]

{ #category : #offset }
StackBuilderTest >> offsetTemp2 [
	^ self offsetStackElement1 + 1
]

{ #category : #running }
StackBuilderTest >> setUp [
	super setUp.
	
	self addComplexFrame.
	self addComplexFrame.	

	builder buildStack.

]

{ #category : #'test-VMstate' }
StackBuilderTest >> testBaseFrameCallerSavedIPShouldBeZero [
	"This test shows that the bottom frame has no previous caller
	so not caller saved instruction pointer."
	self assert: (interpreter frameCallerSavedIP: builder page baseFP) equals: 0
]

{ #category : #'test-VMstate' }
StackBuilderTest >> testNewFrameCallerFPisBaseFrame [
	self assert: (interpreter frameCallerFP: interpreter framePointer) 
		equals: (builder page baseFP)
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderContext [
	self assert: (interpreter internalStackValue: self offsetContext)
		equals: context
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderMethod [
	self assert: (interpreter internalStackValue: self offsetMethod)
		equals: method
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderReceiver [
	self assert: (interpreter internalStackValue: self offsetReceiver)
		equals: receiver
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderStackElementIsReversed [
	self assert: (interpreter internalStackValue: self offsetStackElement1)
		equals: stackElement1.
	self assert: (interpreter internalStackValue: self offsetStackElement2)
		equals: stackElement2.
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderStackTopOfSuspendedProcessIsInstructionPointer [
	"When a process is suspended, the Instruction pointer is pushed on the stack.
	It should be the last thing pushed, and therefore, be at the top. "
	self assert: (interpreter internalStackValue: self offsetInstructionPointer) 
		equals: instructionPointer.
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderTempIsReversed [
	self assert: (interpreter internalStackValue: self offsetTemp1)
		equals: temp1.
	self assert: (interpreter internalStackValue: self offsetTemp2)
		equals: temp2.
]

{ #category : #'test-VMstate' }
StackBuilderTest >> testPageHeadFPIsLastFrameFP [
	"The FramePointer of the interpreter should be the FramePointer of the current process last pushed frame."
	self assert: interpreter framePointer
		equals: builder page headFP
]
