"
This class contains tests for the StackBuilder.

builder <StackBuilder> stack builder used during the tests.

The following IVs are used to test that the stack is ordered correctly in their tests.
(see protocol #test-order)
stackElement1
stackElement2
instructionPointer
receiver
context
temp1
temp2
method
"
Class {
	#name : #StackBuilderTest,
	#superclass : #VMInterpreterTests,
	#instVars : [
		'stackElement1',
		'stackElement2',
		'instructionPointer',
		'receiver',
		'context',
		'temp1',
		'temp2',
		'method',
		'argument2',
		'argument1'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #offset }
StackBuilderTest >> addFullFrame [
	| frame |
	method := methodBuilder newMethod numberOfTemporaries: 2; numberOfArguments: 2; buildMethod.

	frame := stackBuilder addNewFrame.
	instructionPointer := method + 17.
	frame beSuspendedAt: instructionPointer.
	
	stackElement1 := memory integerObjectOf: 4.
	stackElement2 := memory integerObjectOf: 5.
	frame stack: { stackElement1. stackElement2 }.
	
	temp1 := memory integerObjectOf: 6.
	temp2 := memory integerObjectOf: 7.
	frame temps: { temp1. temp2 }.

	receiver := memory integerObjectOf: 8.
	frame receiver: receiver.
	context := memory nilObject.
	frame context: context.

	frame method: method.
	^ frame 
]

{ #category : #offset }
StackBuilderTest >> offsetArgument1 [
	^ self offsetArgument2 + 1
]

{ #category : #offset }
StackBuilderTest >> offsetArgument1FromBaseFP [
	^ self offsetArgument2FromBaseFP + 1
]

{ #category : #offset }
StackBuilderTest >> offsetArgument2 [
	"we skip the frame pointer"
	^ self offsetMethod + 2
]

{ #category : #offset }
StackBuilderTest >> offsetArgument2FromBaseFP [
	^ 2
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
	
	argument2 := memory integerObjectOf: 3.
	argument1 := memory integerObjectOf: 2.
	stackBuilder args: { argument1. argument2 }.
	self addFullFrame.
	self addFullFrame.	
	self addFullFrame.

	stackBuilder buildStack.

]

{ #category : #'test-VMstate' }
StackBuilderTest >> testCallerFrameOfTopFrameShouldBeSecondFrameBuilderObject [
	"For debug purpose, we added a link to the caller frame in the current frame."
	self assert: (stackBuilder topFrame callerFrame) 
		equals: (stackBuilder frames nextToLast)
]

{ #category : #'test-VMstate' }
StackBuilderTest >> testCallerInstructionPointerIsPushedInStack [
	"We have 3 frames. 
	The caller of the caller of the top frame is the first one, which is the base"
	self assert: (interpreter frameCallerSavedIP: interpreter framePointer)
		equals: stackBuilder frames second instructionPointer.
]

{ #category : #'test-setFromMethod' }
StackBuilderTest >> testFrameHasMoreArgumentsThanMethodShouldFail [

	| frame |
	stackBuilder reset.

	method := methodBuilder newMethod buildMethod.
	frame := stackBuilder addNewFrame.
	frame method: method;
		argumentSize: 1.

	self should: [ stackBuilder buildStack ] raise: Error
]

{ #category : #'test-setFromMethod' }
StackBuilderTest >> testFrameHasMoreTemporariesThanMethodShouldFail [
	
	| frame |
	stackBuilder reset.
	
	method := methodBuilder newMethod buildMethod.
	frame := stackBuilder addNewFrame.
	frame method: method;
		temps: { memory nilObject }.

	self should: [ stackBuilder buildStack ] raise: Error
]

{ #category : #'test-VMstate' }
StackBuilderTest >> testHeadFramePointerCallerCallerIsBaseFramePointer [
	"We have 3 frames. 
	The caller of the caller of the top frame is the first one, which is the base"
	self assert: (interpreter frameCallerFP: (interpreter frameCallerFP: interpreter framePointer))
		equals: stackBuilder page baseFP
]

{ #category : #'test-VMstate' }
StackBuilderTest >> testHeadFramePointerCallerIsNotBaseFramePointer [
	"We have 3 frames. 
	The caller of the top frame should be the middle one"
	self deny: (interpreter frameCallerFP: interpreter framePointer) 
		equals: stackBuilder page baseFP
]

{ #category : #'test-setFromMethod' }
StackBuilderTest >> testInstructionPointerIsSetBeforeFirstBytecodeOfLastMethodPushed [

	method := methodBuilder newMethod buildMethod.
	stackBuilder addNewFrame method: method. 
	stackBuilder buildStack.
	
	self assert: interpreter instructionPointer
		equals: (methodBuilder bytecodeAt: 0 forMethod: method)
]

{ #category : #'test-setFromMethod' }
StackBuilderTest >> testMethodHasMoreArgumentsThanFrameShouldUpdateFrame [

	| frame argNum |
	stackBuilder reset.

	argNum := 1.
	method := methodBuilder newMethod ; numberOfArguments: argNum ; buildMethod.
	frame := stackBuilder addNewFrame.
	frame method: method.

	self assert: frame argumentSize equals: 0.
	stackBuilder buildStack.
	self assert: frame argumentSize equals: argNum.
]

{ #category : #'test-setFromMethod' }
StackBuilderTest >> testMethodHasMoreTemporariesThanFrameShouldUpdateFrame [

	| frame tempNum |
	stackBuilder reset.

	tempNum := 1.
	method := methodBuilder newMethod ; numberOfTemporaries: tempNum ; buildMethod.
	frame := stackBuilder addNewFrame.
	frame method: method.

	self assert: frame temps isEmpty.
	stackBuilder buildStack.
	self assert: frame temps equals: (OrderedCollection new: tempNum withAll: memory nilObject).
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderArgument1InBaseFrame [
	self assert: (interpreter stackPages longAtPointer: interpreter stackPage baseFP + (self offsetArgument1FromBaseFP * memory bytesPerOop))
		equals: argument1
]

{ #category : #'test-order' }
StackBuilderTest >> testOrderArgument2InBaseFrame [
	self assert: (interpreter stackPages longAtPointer: interpreter stackPage baseFP + (self offsetArgument2FromBaseFP * memory bytesPerOop))
		equals: argument2
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
	"When a process is suspended, the Instruction Pointer is pushed on the stack of the frame.
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
		equals: stackBuilder page headFP
]
