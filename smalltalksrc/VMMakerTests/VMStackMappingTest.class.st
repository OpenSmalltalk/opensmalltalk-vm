Class {
	#name : #VMStackMappingTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #helpers }
VMStackMappingTest >> buildStackFromFrames [

	3 timesRepeat:[  | method |
		method := methodBuilder newMethod buildMethod.
		stackBuilder addNewFrame 
			method: method;
			beSuspended
		].

	stackBuilder buildStack.

]

{ #category : #helpers }
VMStackMappingTest >> newContext [
	| method |
	method:= methodBuilder newMethod buildMethod.
	^self newSmallContextReceiver: memory nilObject method: method arguments: #() temporaries: #() ip: 10.
]

{ #category : #tests }
VMStackMappingTest >> testCreatingNewContextByHandShouldbeSingle [

	self assert: (interpreter isSingleContext: self newContext)
]

{ #category : #tests }
VMStackMappingTest >> testDivorceAMarriedContextShuoldMakeItSingle [
	| context fp |
	context := self newContext.
	interpreter marryContextInNewStackPageAndInitializeInterpreterRegisters: context.
	fp := interpreter frameOfMarriedContext: context. 
	interpreter externalDivorceFrame: fp andContext: context.
	self assert: (interpreter isSingleContext: context)
]

{ #category : #tests }
VMStackMappingTest >> testDivorceFramesInPage [
	| page |
	self buildStackFromFrames.
	page := stackBuilder page.
	stackBuilder frames do:[ :aFrame |
		aFrame marryToContext.
		].
	stackBuilder frames do:[ :aFrame |
		self assert: aFrame isMarried.
		].
	
	interpreter divorceFramesIn: page.
	
	stackBuilder frames do:[ :aFrame |
		self assert: aFrame isSingle.
		].
	self assert: (interpreter stackPages isFree: page)

]

{ #category : #tests }
VMStackMappingTest >> testMarryNewContextIsMarried [
	| context |
	context := self newContext.
	interpreter marryContextInNewStackPageAndInitializeInterpreterRegisters: context.
	self assert: (interpreter isStillMarriedContext: context)
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceBaseFrameShouldFreeOldPage [
	| aContext framePointerToMarry stackPointerToMarry oldPage |
	self buildStackFromFrames.

	oldPage := interpreter stackPage.
	framePointerToMarry := interpreter stackPage baseFP.
	stackPointerToMarry := interpreter frameCallerSP: (interpreter frameCallerFP: interpreter framePointer).
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.

	self assert: oldPage isFree
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceBaseFrameShouldSetDivorcedContextAsSenderContextInNewPage [
	| aContext framePointerToMarry stackPointerToMarry  expectedDivorcedContext |
	self buildStackFromFrames.

	framePointerToMarry := interpreter stackPage baseFP.
	stackPointerToMarry := interpreter frameCallerSP: (interpreter frameCallerFP: interpreter framePointer).
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	expectedDivorcedContext := interpreter frameCallerContext: interpreter stackPage baseFP.
	
	self assert: expectedDivorcedContext equals: aContext.
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceBaseFrameShouldSplitPage [
	| aContext framePointerToMarry stackPointerToMarry oldPage newPage |
	self buildStackFromFrames.
	
	oldPage := interpreter stackPage.
	framePointerToMarry := interpreter stackPage baseFP.
	stackPointerToMarry := interpreter frameCallerSP: (interpreter frameCallerFP: interpreter framePointer).
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	newPage := interpreter stackPage.
	self deny: oldPage equals: newPage
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceMiddleFrame [
	| aContext framePointerToMarry stackPointerToMarry |
	self buildStackFromFrames.
	
	framePointerToMarry := interpreter frameCallerFP: interpreter framePointer.
	stackPointerToMarry := interpreter frameCallerSP: interpreter framePointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	self assert: (interpreter isSingleContext: aContext).
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceMiddleFrameShouldSetDivorcedContextAsSenderContextInNewPage [
	| aContext framePointerToMarry stackPointerToMarry  expectedDivorcedContext oldBaseFramePointer callerContext |
	self buildStackFromFrames.

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
VMStackMappingTest >> testMarryThenDivorceMiddleFrameShouldSplitPage [
	| aContext framePointerToMarry stackPointerToMarry initialiNumberOfusedPages newNumberOfUsedPages |
	self buildStackFromFrames.
	
	initialiNumberOfusedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	framePointerToMarry := interpreter frameCallerFP: interpreter framePointer.
	stackPointerToMarry := interpreter frameCallerSP: interpreter framePointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	newNumberOfUsedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	self assert: initialiNumberOfusedPages + 1 equals: newNumberOfUsedPages
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceTopFrame [
	| aContext framePointerToMarry stackPointerToMarry |
	self buildStackFromFrames.
	
	framePointerToMarry := interpreter framePointer.
	stackPointerToMarry := interpreter stackPointer.
	aContext := interpreter ensureFrameIsMarried: framePointerToMarry SP: stackPointerToMarry.
	interpreter externalDivorceFrame: framePointerToMarry andContext: aContext.
	self assert: (interpreter isSingleContext: aContext).
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryThenDivorceTopFrameShouldNotSplitPage [
	| aContext initialiNumberOfusedPages newNumberOfUsedPages |
	self buildStackFromFrames.

	initialiNumberOfusedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	aContext := interpreter ensureFrameIsMarried: interpreter framePointer SP: interpreter stackPointer.
	interpreter externalDivorceFrame: interpreter framePointer andContext: aContext.
	newNumberOfUsedPages := interpreter stackPages pages count:[ :aPage | aPage isFree not ].
	self assert: initialiNumberOfusedPages equals: 	newNumberOfUsedPages
]

{ #category : #'test-context-tomove' }
VMStackMappingTest >> testMarryTopFrame [
	| aContext |
	self buildStackFromFrames.
	
	aContext := interpreter ensureFrameIsMarried: interpreter framePointer SP: interpreter stackPointer.
	self assert: (interpreter isStillMarriedContext: aContext).
]
