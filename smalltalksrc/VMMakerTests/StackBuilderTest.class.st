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
		'method'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #'helper-frame' }
StackBuilderTest >> addFullFrame [
	| frame |

	method := self newMethodWithBytecodes: #[1 2 3 4 5 6 7 8 ].

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

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceBaseFrameShouldFreeOldPage [
	| aContext framePointerToMarry stackPointerToMarry oldPage |
	"should be moved in VMStackMappingTest after merge."
	oldPage := interpreter stackPage.
	framePointerToMarry := interpreter stackPage baseFP.
	stackPointerToMarry := interpreter frameCallerSP: (interpreter frameCallerFP: interpreter framePointer).
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.

	self assert: oldPage isFree
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceBaseFrameShouldSetDivorcedContextAsSenderContextInNewPage [
	| aContext framePointerToMarry stackPointerToMarry  expectedDivorcedContext |
	"should be moved in VMStackMappingTest after merge."

	framePointerToMarry := interpreter stackPage baseFP.
	stackPointerToMarry := interpreter frameCallerSP: (interpreter frameCallerFP: interpreter framePointer).
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	expectedDivorcedContext := interpreter frameCallerContext: interpreter stackPage baseFP.
	
	self assert: expectedDivorcedContext equals: aContext.
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceBaseFrameShouldSplitPage [
	| aContext framePointerToMarry stackPointerToMarry oldPage newPage |
	"should be moved in VMStackMappingTest after merge."
	oldPage := interpreter stackPage.
	framePointerToMarry := interpreter stackPage baseFP.
	stackPointerToMarry := interpreter frameCallerSP: (interpreter frameCallerFP: interpreter framePointer).
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	newPage := interpreter stackPage.
	self deny: oldPage equals: newPage
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceMiddleFrame [
	| aContext framePointerToMarry stackPointerToMarry |
	"should be moved in VMStackMappingTest after merge."
	framePointerToMarry := interpreter frameCallerFP: interpreter framePointer.
	stackPointerToMarry := interpreter frameCallerSP: interpreter framePointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	self assert: (interpreter isSingleContext: aContext).
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceMiddleFrameShouldSetDivorcedContextAsSenderContextInNewPage [
	| aContext framePointerToMarry stackPointerToMarry  expectedDivorcedContext oldBaseFramePointer callerContext |
	"should be moved in VMStackMappingTest after merge."

	framePointerToMarry := interpreter frameCallerFP: interpreter framePointer.
	stackPointerToMarry := interpreter frameCallerSP: interpreter framePointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	oldBaseFramePointer := interpreter stackPage baseFP.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	expectedDivorcedContext := interpreter frameCallerContext: interpreter stackPage baseFP.
	
	self assert: (interpreter frameHasContext: oldBaseFramePointer).
	self assert: expectedDivorcedContext equals: aContext.
	callerContext := interpreter frameContext: oldBaseFramePointer.
	
	self assert: (memory fetchPointer: SenderIndex ofObject: expectedDivorcedContext) equals: callerContext.
	
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceMiddleFrameShouldSplitPage [
	| aContext framePointerToMarry stackPointerToMarry initialiNumberOfusedPages newNumberOfUsedPages |
	"should be moved in VMStackMappingTest after merge."
	initialiNumberOfusedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	framePointerToMarry := interpreter frameCallerFP: interpreter framePointer.
	stackPointerToMarry := interpreter frameCallerSP: interpreter framePointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	newNumberOfUsedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	self assert: initialiNumberOfusedPages + 1 equals: newNumberOfUsedPages
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceTopFrame [
	| aContext framePointerToMarry stackPointerToMarry |
	"should be moved in VMStackMappingTest after merge."
	framePointerToMarry := interpreter framePointer.
	stackPointerToMarry := interpreter stackPointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	self assert: (interpreter isSingleContext: aContext).
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryThenDivorceTopFrameShouldNotSplitPage [
	| aContext initialiNumberOfusedPages newNumberOfUsedPages |
	"should be moved in VMStackMappingTest after merge."

	initialiNumberOfusedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	aContext := interpreter ensureFrameIsMarried: interpreter framePointer SP: interpreter stackPointer.
	interpreter externalDivorceFrame: interpreter framePointer andContext: aContext.
	newNumberOfUsedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	self assert: initialiNumberOfusedPages equals: 	newNumberOfUsedPages
]

{ #category : #'test-context-tomove' }
StackBuilderTest >> testMarryTopFrame [
	| aContext |
	"should be moved in VMStackMappingTest after merge."
	aContext := interpreter ensureFrameIsMarried: interpreter framePointer SP: interpreter stackPointer.
	self assert: (interpreter isStillMarriedContext: aContext).
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
