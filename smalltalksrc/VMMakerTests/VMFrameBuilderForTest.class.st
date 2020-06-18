Class {
	#name : #VMFrameBuilderForTest,
	#superclass : #Object,
	#instVars : [
		'method',
		'context',
		'receiver',
		'args',
		'temps',
		'stack',
		'memory',
		'page',
		'interpreter',
		'senderContext'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
VMFrameBuilderForTest >> args [
	^ args
]

{ #category : #accessing }
VMFrameBuilderForTest >> args: anObject [
	args := anObject
]

{ #category : #building }
VMFrameBuilderForTest >> buildFrame [
	self createStackPage.
	self pushMethod.

	"Flags: this stack frame is single. I.e., it has no context object.
	Otherwise GC fails with an assertion looking for it in the heap"
	interpreter
		push:
			(interpreter
				encodeFrameFieldHasContext: context ~= memory nilObject
				isBlock: false
				numArgs: args size).
				
				
	interpreter push: context.
	interpreter push: receiver.
	
	temps do: [ :oop |  interpreter push: oop ].
	
	"push to the stack all objects in the frame stack"
	stack do: [ :oop | interpreter push: oop ].	"ip"
	
	interpreter push: method + memory baseHeaderSize - 2.
	page headSP: interpreter stackPointer.
	interpreter setStackPageAndLimit: page.
	interpreter setStackPointersFromPage: page.
	interpreter popStack.
	
	
	context ~= memory nilObject
		ifTrue: [ memory
				storePointerUnchecked: 0
				ofObject: context
				withValue: (interpreter withSmallIntegerTags: page baseFP)	"SenderIndex" ]
]

{ #category : #accessing }
VMFrameBuilderForTest >> context [
	^ context
]

{ #category : #accessing }
VMFrameBuilderForTest >> context: anObject [
	context := anObject
]

{ #category : #building }
VMFrameBuilderForTest >> createStackPage [
	| pointer |
	page := interpreter stackPages newStackPage.
	pointer := page baseAddress.
	interpreter stackPointer: pointer + memory wordSize.
]

{ #category : #initialization }
VMFrameBuilderForTest >> initializeForTest: aVMByteCodesTest [ 
	memory := aVMByteCodesTest memory.
	interpreter := aVMByteCodesTest interpreter. "allow to not care if it's for a cog or stack interpreter"
	method := memory nilObject.
	context := memory nilObject.
	receiver := memory nilObject.
	args := OrderedCollection new.
	temps := OrderedCollection new.
	stack := OrderedCollection new.
	

	senderContext := memory nilObject.
]

{ #category : #accessing }
VMFrameBuilderForTest >> method [
	^ method
]

{ #category : #accessing }
VMFrameBuilderForTest >> method: anObject [
	method := anObject
]

{ #category : #building }
VMFrameBuilderForTest >> pushContext [
	interpreter push: context.
	interpreter push: receiver.
	stack do: [ :aMemoryObject | interpreter push: aMemoryObject ].
	"ip"
	interpreter push: (method + memory baseHeaderSize - 2).
	page headSP: interpreter stackPointer.
	interpreter setStackPageAndLimit: page.
	interpreter setStackPointersFromPage: page.
	interpreter popStack.
]

{ #category : #building }
VMFrameBuilderForTest >> pushMethod [
	"page has to be created first"
	
	interpreter push: receiver.
	args do: [ :anArg | interpreter push: anArg ].
	interpreter push: senderContext.
	"base frame's saved fp is null"
	memory coInterpreter push: 0.
	page
		baseFP: interpreter stackPointer;
		headFP: interpreter stackPointer.
	interpreter push: method.
]

{ #category : #accessing }
VMFrameBuilderForTest >> receiver [
	^ receiver
]

{ #category : #accessing }
VMFrameBuilderForTest >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
VMFrameBuilderForTest >> stack [
	^ stack
]

{ #category : #accessing }
VMFrameBuilderForTest >> stack: anObject [
	stack := anObject
]

{ #category : #accessing }
VMFrameBuilderForTest >> tempAt: anIndex put: anOop [
	temps size > anIndex ifTrue: [ ^ temps at: anIndex + 1 put: anOop ].
	
	temps size to: anIndex do: [ :i | temps add: memory nilObject ].
	temps at: anIndex + 1 put: anOop
	
]

{ #category : #accessing }
VMFrameBuilderForTest >> temps [
	^ temps
]

{ #category : #accessing }
VMFrameBuilderForTest >> temps: anObject [
	temps := anObject
]
