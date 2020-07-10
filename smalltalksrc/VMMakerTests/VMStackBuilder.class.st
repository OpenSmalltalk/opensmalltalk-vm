"
I am a builder for Stack frames.

I am configuring frames and building the stack frames.

I am used by tests for the simulator.
I am creating the page that I will put in the interpreter.
I am using the VMFrameBuilder to prepare the frame objects that I will push on the stack.

You can either give me a frame ready to add with #addFrame:
You can also use #addNewFrame:. This creates an frames, add it, then returns it to be configured.
When all the frames have been added, use #buildStack to create the stack.
I need a reference to an interpreter and memory to work.

examples can be found in #VMByteCodetests
for example: 
self stackBuilder addNewFrame receiver: intReceiver.
self stackBuilder buildStack.
 
Internal Representation and Key Implementation Points.

Types are not the exact types used.
    Instance Variables
	frames:		<OrderedCollection> collection of the frames to be added. First frame added in the collection, first frame pushed.
	interpreter:		<Interpreter> an interpreter simulator.
	memory:		<Memory> a memory simulator
	page:		<StackPage> a new page containing the stack to be added

"
Class {
	#name : #VMStackBuilder,
	#superclass : #Object,
	#instVars : [
		'page',
		'frames',
		'interpreter',
		'memory'
	],
	#category : #'VMMakerTests-Frame'
}

{ #category : #frames }
VMStackBuilder >> addFrame: aFrame [
	frames add: aFrame
]

{ #category : #frames }
VMStackBuilder >> addNewFrame [
	| frame |
	"'add' a new frame in the sense of an OrderedCollection, which will be iterated with #do:
	The last frame added, will be the stackTop"
	frame := VMFrameBuilder new initializeWithInterpreter: interpreter andMemory: memory.
	frames add: frame.
	^ frame "the frame is then configured by the caller"
]

{ #category : #build }
VMStackBuilder >> buildStack [
	| lastFrame |
	self createStackPage.
	self pushFrames.

	lastFrame := frames last.
	
"	interpreter push: lastFrame method + memory baseHeaderSize - 2.
	interpreter setStackPageAndLimit: page.
	interpreter setStackPointersFromPage: page.
""	interpreter popStack."
	"should return last frame in use" 
	
	"page
		headFP: lastFrame temps size + 5 + interpreter stackPointer;
		headSP: interpreter stackPointer.
	"
	"interpreter stackTop.
	interpreter stackPages.
	"
	
	interpreter setStackPageAndLimit: page.
  interpreter setStackPointersFromPage: page.
	interpreter internalizeIPandSP.
	^ lastFrame
]

{ #category : #stack }
VMStackBuilder >> createStackPage [
	| sp |
	frames ifEmpty:[ self error ].

	page := interpreter stackPages newStackPage.
	"set base stackPointer"
	sp := page baseAddress - (memory wordSize * (frames first args size + 2)).
	interpreter stackPointer: sp.
	interpreter framePointer: sp.

	
]

{ #category : #accessing }
VMStackBuilder >> frames [
	^ frames
]

{ #category : #Initialization }
VMStackBuilder >> initialize [
	super initialize.
	frames := OrderedCollection new. "will be treated in reverse"
]

{ #category : #accessing }
VMStackBuilder >> interpreter [
	^ interpreter
]

{ #category : #accessing }
VMStackBuilder >> interpreter: anInterpreter [
	interpreter := anInterpreter
]

{ #category : #accessing }
VMStackBuilder >> memory [
	^ memory
]

{ #category : #accessing }
VMStackBuilder >> memory: aMemory [
	memory := aMemory
]

{ #category : #accessing }
VMStackBuilder >> page [
	^ page
]

{ #category : #build }
VMStackBuilder >> pushFrames [
	| first lastFrame |
	first := true.
	page
		headSP: interpreter stackPointer;
		headFP: interpreter stackPointer.

	lastFrame := nil.
	frames
		do: [ :aFrame |
			
			first ifTrue:[ 
					interpreter push: 0.
					interpreter push: interpreter framePointer.
					page baseFP: interpreter stackPointer.
					first := false.
				]
				ifFalse:[ 
					interpreter push: interpreter instructionPointer.
					interpreter push: interpreter framePointer.
				].
			
			aFrame callerFrame: lastFrame.
			lastFrame := aFrame.
			interpreter framePointer: interpreter stackPointer.
			page headFP: interpreter stackPointer.

			aFrame pushYourself.
			page headSP: interpreter stackPointer.
			]
]

{ #category : #accessing }
VMStackBuilder >> topFrame [
	^ frames last
]
