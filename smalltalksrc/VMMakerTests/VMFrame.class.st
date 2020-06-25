Class {
	#name : #VMFrame,
	#superclass : #Object,
	#instVars : [
		'method',
		'context',
		'receiver',
		'args',
		'temps',
		'stack',
		'memory',
		'interpreter',
		'senderContext',
		'previousFrame',
		'page',
		'instructionPointer'
	],
	#category : #'VMMakerTests-Frame'
}

{ #category : #inspect }
VMFrame >> adaptAddressToMemory: anInteger [
	anInteger = memory nilObject ifTrue: [ ^ #nilObject ].
	anInteger = memory trueObject ifTrue: [ ^ #trueObject ].
	anInteger = memory falseObject ifTrue: [ ^ #falseObject ].
	^ anInteger
	"^ memory integerObjectOf: anInteger"
]

{ #category : #inspect }
VMFrame >> adaptAddressToMemoryIfInteger: anAssociation [	
	anAssociation value isInteger
	ifTrue: [ anAssociation value: (self adaptAddressToMemory: anAssociation value) ]

]

{ #category : #accessing }
VMFrame >> args [
	^ args
]

{ #category : #accessing }
VMFrame >> args: anObject [
	args := anObject
]

{ #category : #configuring }
VMFrame >> beSuspendedAt: anInstructionPointer [
	instructionPointer := anInstructionPointer 
]

{ #category : #accessing }
VMFrame >> context [
	^ context
]

{ #category : #accessing }
VMFrame >> context: anObject [
	context := anObject
]

{ #category : #inspect }
VMFrame >> gtInspectorItemsIn: composite [
	<gtInspectorPresentationOrder: 1>

	| values |
	values :={
		#stack -> stack.
		#temps -> temps.
		#receiver -> receiver.
		#context -> nil.
		#flags ->  nil.
		#method ->  method.
		#'caller''s method ip' -> nil.
		#arguments -> args.
		#receiver -> receiver.
		 }.
	^ composite fastTable
		title: 'frame';
		display: [ values ];
		column: 'names' evaluated: [ :anAssociation | 
			(anAssociation value isCollection and: [ anAssociation value isString not])
			 ifTrue: [ GTObjectPrinter asNonTruncatedTextFrom: anAssociation key -> 
					(anAssociation value asArray 
						collect:[ :each | (self adaptAddressToMemoryIfInteger: nil -> each) value ])]
			ifFalse:[  
				self adaptAddressToMemoryIfInteger: anAssociation.
					].
				GTObjectPrinter asNonTruncatedTextFrom: anAssociation ]
	

]

{ #category : #initialization }
VMFrame >> initializeWithInterpreter: anInterpreter andMemory: aMemory [
	memory := aMemory.
	interpreter := anInterpreter. "allow to not care if it's for a cog or stack interpreter"
	method := memory nilObject.
	context := memory nilObject.
	receiver := memory nilObject.
	args := OrderedCollection new.
	temps := OrderedCollection new.
	stack := OrderedCollection new.
	

	senderContext := memory nilObject.
]

{ #category : #testing }
VMFrame >> isSuspended [
	^ instructionPointer = nil
]

{ #category : #accessing }
VMFrame >> method [
	^ method
]

{ #category : #accessing }
VMFrame >> method: anObject [
	method := anObject
]

{ #category : #building }
VMFrame >> page [
	^ page
]

{ #category : #building }
VMFrame >> page: aPageOop [
	page := aPageOop
]

{ #category : #accessing }
VMFrame >> previousFrame [
	^ previousFrame
]

{ #category : #accessing }
VMFrame >> previousFrame: aFrame [
	previousFrame := aFrame
]

{ #category : #building }
VMFrame >> pushCurrentFramesStack [
	"push to the stack all objects in the frame stack"
	stack do: [ :oop | interpreter push: oop ].	
]

{ #category : #building }
VMFrame >> pushFlags [
	"Flags: this stack frame is single. I.e., it has no context object.
	Otherwise GC fails with an assertion looking for it in the heap"
	interpreter push:
		(interpreter
			encodeFrameFieldHasContext: context ~= memory nilObject
			isBlock: false
			numArgs: args size).
]

{ #category : #building }
VMFrame >> pushFrame [
	interpreter push: context.
	interpreter push: receiver.
	
	temps do: [ :oop |  interpreter push: oop ].
]

{ #category : #building }
VMFrame >> pushYourself [
	interpreter push: method.
	self pushFlags.
	self pushFrame.
	self pushCurrentFramesStack.
		
	
	"context ~= memory nilObject
		ifTrue: [ memory
				storePointerUnchecked: 0
				ofObject: context
				withValue: (interpreter withSmallIntegerTags: page baseFP)	""SenderIndex"" ]."
				
	instructionPointer ifNotNil: [ interpreter push: instructionPointer ].
	
	^ interpreter framePointer
]

{ #category : #accessing }
VMFrame >> receiver [
	^ receiver
]

{ #category : #accessing }
VMFrame >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
VMFrame >> stack [
	^ stack
]

{ #category : #accessing }
VMFrame >> stack: anObject [
	stack := anObject
]

{ #category : #building }
VMFrame >> storePreviousFrame [
	previousFrame ifNil: [ ^ self ].
	
	interpreter push: 0. " push caller Instruction Pointer "
	interpreter push: previousFrame.
	interpreter framePointer: interpreter stackPointer
]

{ #category : #accessing }
VMFrame >> tempAt: anIndex put: anOop [
	temps size > anIndex ifTrue: [ ^ temps at: anIndex + 1 put: anOop ].
	
	temps size to: anIndex do: [ :i | temps add: memory nilObject ].
	temps at: anIndex + 1 put: anOop
	
]

{ #category : #accessing }
VMFrame >> temps [
	^ temps
]

{ #category : #accessing }
VMFrame >> temps: anObject [
	temps := anObject
]
