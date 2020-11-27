"
I represent a frame in a stack which is in a page.

I am representing a frame.
I am able to push myself on the interpreter stack's provided when I'm asked to do so.
I only know my own state.
I have a specific inspector

I am currently used only in the #VMStackBuilder, which configures my instances, and is asking me to push myself on the interpreter.


API
I required an interpreter/memory to be able to initialize myself, so initialization is done using #initializeWithInterpreter:.
Configuring is done by using accessing protocol's methods.
When ready, tell me to push myself with #pushYourself.


 
Internal Representation and Key Implementation Points.

Unfinished comment.

    Instance Variables
	interpreter:		<Interpreter> Stack or Cog, it shouldn't matter. Allows interaction with the current *simulation* interpreter
	memory:		<SpurMemorySomething> Same as interpreter, but for memory *simulation* version

Configuring of the frame.
	args:		<Object>

	context:		<Object>
	instructionPointer:		<Object>
	method:		<Object>
	receiver:		<Object>
	senderContext:		<Object>

	temps:		<Object>
	stack:		<Object>

	This IVs are present solely for inspection purpose.	
	flags: <SmallInteger?> This is calculated by the VM, and should not be set by hand.
	callerFP:		<VMFrambeBuilder?> When the stack builder is pushing several frames, it links them.
			When it links them, it gives the last frame the previous caller Frame, for debug purpose.
"
Class {
	#name : #VMFrameBuilder,
	#superclass : #VMAbstractBuilder,
	#instVars : [
		'method',
		'context',
		'receiver',
		'temps',
		'stack',
		'instructionPointer',
		'callerFrame',
		'flags',
		'previousFrameArgsSize',
		'argumentSize',
		'myFramePointer',
		'myStackPointer',
		'vmMethodBuilder',
		'methodBuilder',
		'isSuspended'
	],
	#category : #'VMMakerTests-Builders'
}

{ #category : #inspect }
VMFrameBuilder >> adaptAddressToMemory: anInteger [
	anInteger = memory nilObject ifTrue: [ ^ #nilObject ].
	anInteger = memory trueObject ifTrue: [ ^ #trueObject ].
	anInteger = memory falseObject ifTrue: [ ^ #falseObject ].
	^ anInteger
	"^ memory integerObjectOf: anInteger"
]

{ #category : #inspect }
VMFrameBuilder >> adaptAddressToMemoryIfInteger: anAssociation [	
	anAssociation value isInteger
	ifTrue: [ anAssociation value: (self adaptAddressToMemory: anAssociation value) ]

]

{ #category : #accessing }
VMFrameBuilder >> argumentSize [
	^ argumentSize
]

{ #category : #accessing }
VMFrameBuilder >> argumentSize: anObject [
	argumentSize := anObject
]

{ #category : #configuring }
VMFrameBuilder >> beSuspended [
	isSuspended := true
]

{ #category : #configuring }
VMFrameBuilder >> beSuspendedAt: anInstructionPointer [
	instructionPointer := anInstructionPointer.
	self beSuspended
]

{ #category : #accessing }
VMFrameBuilder >> callerFrame [
	^ callerFrame
]

{ #category : #accessing }
VMFrameBuilder >> callerFrame: aFrame [ 
	callerFrame := aFrame
]

{ #category : #accessing }
VMFrameBuilder >> context [
	^ context
]

{ #category : #accessing }
VMFrameBuilder >> context: anObject [
	context := anObject
]

{ #category : #accessing }
VMFrameBuilder >> flags [
	^ flags
]

{ #category : #accessing }
VMFrameBuilder >> flags: anObject [
	flags := anObject
]

{ #category : #accessing }
VMFrameBuilder >> framePointer [
	^ myFramePointer
]

{ #category : #inspect }
VMFrameBuilder >> gtInspectorItemsIn: composite [
	<gtInspectorPresentationOrder: 1>

	| values |
	values :={
		#stack -> stack.
		#temps -> temps.
		#receiver -> receiver.
		#context -> context.
		#flags ->  flags.
		#method ->  method.
		#'caller''s method ip' -> nil.
		#'callerFP' -> callerFrame.
"		#arguments -> args."
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
VMFrameBuilder >> initializeWithInterpreter: anInterpreter andMemory: aMemory andMethodBuilder: aMethodBuilder [
	memory := aMemory.
	interpreter := anInterpreter. "allow to not care if it's for a cog or stack interpreter"
	methodBuilder := aMethodBuilder.
	method := memory nilObject.
	context := memory nilObject.
	receiver := memory nilObject.
	temps := OrderedCollection new.
	stack := OrderedCollection new.
	instructionPointer := 0.
	isSuspended := false.
	
	previousFrameArgsSize := 0. " set by the StackBuilder"
	argumentSize := 0.
]

{ #category : #accessing }
VMFrameBuilder >> instructionPointer [
	^ instructionPointer
]

{ #category : #context }
VMFrameBuilder >> isMarried [
	| contextOop |
	contextOop := interpreter frameContext: myFramePointer.
	^ contextOop = memory nilObject 
		ifTrue: [ false ]
		ifFalse: [ interpreter isStillMarriedContext: contextOop ]
]

{ #category : #context }
VMFrameBuilder >> isSingle [
	| contextOop |
	contextOop := interpreter frameContext: myFramePointer.
	^ contextOop = memory nilObject 
		ifTrue: [ true ]
		ifFalse: [ 
			"this means that it was married, and that the context stack entry wasn't cleared"
			interpreter isSingleContext: contextOop ]
]

{ #category : #testing }
VMFrameBuilder >> isSuspended [
	^ isSuspended
]

{ #category : #context }
VMFrameBuilder >> marryToContext [
	interpreter ensureFrameIsMarried: myFramePointer SP: myStackPointer
]

{ #category : #accessing }
VMFrameBuilder >> method [
	^ method
]

{ #category : #accessing }
VMFrameBuilder >> method: anOop [
	method := anOop
]

{ #category : #accessing }
VMFrameBuilder >> previousFrameArgsSize [
	^ previousFrameArgsSize
]

{ #category : #accessing }
VMFrameBuilder >> previousFrameArgsSize: anObject [
	previousFrameArgsSize := anObject
]

{ #category : #building }
VMFrameBuilder >> pushCurrentFramesStack [
	"push to the stack all objects in the frame stack"
	stack do: [ :oop | interpreter push: oop ].	
]

{ #category : #building }
VMFrameBuilder >> pushFlags [
	"Flags: this stack frame is single. I.e., it has no context object.
	Otherwise GC fails with an assertion looking for it in the heap"
	flags := (interpreter
			encodeFrameFieldHasContext: context ~= memory nilObject
			isBlock: false
			numArgs: previousFrameArgsSize).
	interpreter push: flags
]

{ #category : #building }
VMFrameBuilder >> pushFrame [
	interpreter push: context.
	interpreter push: receiver.
	
	temps do: [ :oop |  interpreter push: oop ].
]

{ #category : #building }
VMFrameBuilder >> pushYourself [
	interpreter push: method.
	self setInstructionPointerBeforeFirstBytecode.
	self pushFlags.
	self pushFrame.
	self pushCurrentFramesStack.
		
	
	"context ~= memory nilObject
		ifTrue: [ memory
				storePointerUnchecked: 0
				ofObject: context
				withValue: (interpreter withSmallIntegerTags: page baseFP)	""SenderIndex"" ]."
				
	isSuspended ifTrue: [ interpreter push: instructionPointer ].
	
	myStackPointer:= interpreter stackPointer.
	myFramePointer := interpreter framePointer.
	^ myFramePointer
]

{ #category : #accessing }
VMFrameBuilder >> receiver [
	^ receiver
]

{ #category : #accessing }
VMFrameBuilder >> receiver: anObject [
	receiver := anObject
]

{ #category : #building }
VMFrameBuilder >> setInstructionPointerBeforeFirstBytecode [

	"If possible, setting IP to before the first bytecode, so it is ready for fetchNextBytecode"

	((memory isCompiledMethod: method) and: [ instructionPointer = 0 ]) 
		ifTrue: [ 
			instructionPointer := methodBuilder bytecodeAt: 0 forMethod: method.
			interpreter instructionPointer: instructionPointer ]
]

{ #category : #accessing }
VMFrameBuilder >> stack [
	^ stack
]

{ #category : #accessing }
VMFrameBuilder >> stack: anObject [
	stack := anObject
]

{ #category : #accessing }
VMFrameBuilder >> stackPointer [
	^ myStackPointer
]

{ #category : #accessing }
VMFrameBuilder >> tempAt: anIndex put: anOop [
	self collection: temps at: anIndex put: anOop
]

{ #category : #accessing }
VMFrameBuilder >> temps [
	^ temps
]

{ #category : #accessing }
VMFrameBuilder >> temps: anObject [
	temps := anObject
]

{ #category : #accessing }
VMFrameBuilder >> vmMethodBuilder [

	^ vmMethodBuilder
]

{ #category : #accessing }
VMFrameBuilder >> vmMethodBuilder: anObject [

	vmMethodBuilder := anObject
]
